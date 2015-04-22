// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDLCSymbolTable.h"

#include <mach-o/nlist.h>
#import "CDMachOFile.h"
#import "CDSymbol.h"
#import "CDLCSegment.h"
#import "CDLCDylib.h"

@implementation CDLCSymbolTable
{
    struct symtab_command _symtabCommand;
    
    NSArray *_symbols;
    NSUInteger _baseAddress;
    
    NSDictionary *_classSymbols;
    NSDictionary *_externalClassSymbols;
    
    struct {
        unsigned int didFindBaseAddress:1;
        unsigned int didWarnAboutUnfoundBaseAddress:1;
        unsigned int _unused:30;
    } _flags;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        _symtabCommand.cmd     = [cursor readInt32];
        _symtabCommand.cmdsize = [cursor readInt32];
        
        _symtabCommand.symoff  = [cursor readInt32];
        _symtabCommand.nsyms   = [cursor readInt32];
        _symtabCommand.stroff  = [cursor readInt32];
        _symtabCommand.strsize = [cursor readInt32];
        
        // symoff is at the start of the first section (__pointers) of the __IMPORT segment
        // stroff falls within the __LINKEDIT segment
#if 0
        NSLog(@"symtab: %08x %08x  %08x %08x %08x %08x",
              symtabCommand.cmd, symtabCommand.cmdsize,
              symtabCommand.symoff, symtabCommand.nsyms, symtabCommand.stroff, symtabCommand.strsize);
        NSLog(@"data offset for stroff: %lu", [cursor.machOFile dataOffsetForAddress:symtabCommand.stroff]);
#endif
        
        _symbols = nil;
        _baseAddress = 0;
        
        _classSymbols = nil;
        
        _flags.didFindBaseAddress = NO;
        _flags.didWarnAboutUnfoundBaseAddress = NO;
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)extraDescription;
{
    return [NSString stringWithFormat:@"symoff: 0x%08x (%u), nsyms: 0x%08x (%u), stroff: 0x%08x (%u), strsize: 0x%08x (%u)",
            _symtabCommand.symoff, _symtabCommand.symoff, _symtabCommand.nsyms, _symtabCommand.nsyms,
            _symtabCommand.stroff, _symtabCommand.stroff, _symtabCommand.strsize, _symtabCommand.strsize];
}

#pragma mark -

- (uint32_t)cmd;
{
    return _symtabCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return _symtabCommand.cmdsize;
}

#define CD_VM_PROT_RW (VM_PROT_READ|VM_PROT_WRITE)

- (void)loadSymbols;
{
    for (CDLoadCommand *loadCommand in [self.machOFile loadCommands]) {
        if ([loadCommand isKindOfClass:[CDLCSegment class]]) {
            CDLCSegment *segment = (CDLCSegment *)loadCommand;

            if (([segment initprot] & CD_VM_PROT_RW) == CD_VM_PROT_RW) {
                //NSLog(@"segment... initprot = %08x, addr= %016lx *** r/w", [segment initprot], [segment vmaddr]);
                _baseAddress = [segment vmaddr];
                _flags.didFindBaseAddress = YES;
                break;
            }
        }
    }
    
    NSMutableArray *symbols = [[NSMutableArray alloc] init];
    NSMutableDictionary *classSymbols = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *externalClassSymbols = [[NSMutableDictionary alloc] init];

    CDMachOFileDataCursor *cursor = [[CDMachOFileDataCursor alloc] initWithFile:self.machOFile offset:_symtabCommand.symoff];
    //NSLog(@"offset= %lu", [cursor offset]);
    //NSLog(@"stroff=  %lu", symtabCommand.stroff);
    //NSLog(@"strsize= %lu", symtabCommand.strsize);

    const char *strtab = (char *)[self.machOFile.data bytes] + _symtabCommand.stroff;
    
    void (^addSymbol)(NSString *, CDSymbol *) = ^(NSString *name, CDSymbol *symbol) {
        [symbols addObject:symbol];
        
        NSString *className = [CDSymbol classNameFromSymbolName:symbol.name];
        if (className != nil) {
            if (symbol.value != 0)
                classSymbols[className] = symbol;
            else
                externalClassSymbols[className] = symbol;
        }
    };

    if (![self.machOFile uses64BitABI]) {
        //NSLog(@"32 bit...");
        //NSLog(@"       str table index  type  sect  desc  value");
        //NSLog(@"       ---------------  ----  ----  ----  --------");
        for (uint32_t index = 0; index < _symtabCommand.nsyms; index++) {
            struct nlist nlist;

            nlist.n_un.n_strx = [cursor readInt32];
            nlist.n_type      = [cursor readByte];
            nlist.n_sect      = [cursor readByte];
            nlist.n_desc      = [cursor readInt16];
            nlist.n_value     = [cursor readInt32];
#if 0
            NSLog(@"%5u: %08x           %02x    %02x  %04x  %08x - %s",
                  index, nlist.n_un.n_strx, nlist.n_type, nlist.n_sect, nlist.n_desc, nlist.n_value, strtab + nlist.n_un.n_strx);
#endif

            const char *ptr = strtab + nlist.n_un.n_strx;
            NSString *str = [[NSString alloc] initWithBytes:ptr length:strlen(ptr) encoding:NSASCIIStringEncoding];

            CDSymbol *symbol = [[CDSymbol alloc] initWithName:str machOFile:self.machOFile nlist32:nlist];
            addSymbol(str, symbol);
        }

        //NSLog(@"Loaded %lu 32-bit symbols", [symbols count]);
    } else {
        //NSLog(@"       str table index  type  sect  desc  value");
        //NSLog(@"       ---------------  ----  ----  ----  ----------------");
        for (uint32_t index = 0; index < _symtabCommand.nsyms; index++) {
            struct nlist_64 nlist;

            nlist.n_un.n_strx = [cursor readInt32];
            nlist.n_type      = [cursor readByte];
            nlist.n_sect      = [cursor readByte];
            nlist.n_desc      = [cursor readInt16];
            nlist.n_value     = [cursor readInt64];
#if 0
            NSLog(@"%5u: %08x           %02x    %02x  %04x  %016x - %s",
                  index, nlist.n_un.n_strx, nlist.n_type, nlist.n_sect, nlist.n_desc, nlist.n_value, strtab + nlist.n_un.n_strx);
#endif
            const char *ptr = strtab + nlist.n_un.n_strx;
            NSString *str = [[NSString alloc] initWithBytes:ptr length:strlen(ptr) encoding:NSASCIIStringEncoding];

            CDSymbol *symbol = [[CDSymbol alloc] initWithName:str machOFile:self.machOFile nlist64:nlist];
            addSymbol(str, symbol);
        }

        //NSLog(@"Loaded %lu 64-bit symbols", [symbols count]);
    }
    
    _symbols = [symbols copy];
    _classSymbols = [classSymbols copy];
    _externalClassSymbols = [externalClassSymbols copy];

    //NSLog(@"symbols: %@", _symbols);
}

- (uint32_t)symoff;
{
    return _symtabCommand.symoff;
}

- (uint32_t)nsyms;
{
    return _symtabCommand.nsyms;
}

- (uint32_t)stroff;
{
    return _symtabCommand.stroff;
}

- (uint32_t)strsize;
{
    return _symtabCommand.strsize;
}

- (NSUInteger)baseAddress;
{
    if (_flags.didFindBaseAddress == NO && _flags.didWarnAboutUnfoundBaseAddress == NO) {
        fprintf(stderr, "Warning: Couldn't find first read/write segment for base address of relocation entries.\n");
        _flags.didWarnAboutUnfoundBaseAddress = YES;
    }

    return _baseAddress;
}

- (CDSymbol *)symbolForClassName:(NSString *)className;
{
    return _classSymbols[className];
}

- (CDSymbol *)symbolForExternalClassName:(NSString *)className
{
    return _externalClassSymbols[className];
}

@end
