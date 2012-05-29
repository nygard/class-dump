// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDLCSymbolTable.h"

#include <mach-o/nlist.h>
#import "CDMachOFile.h"
#import "CDSymbol.h"
#import "CDLCSegment.h"

@implementation CDLCSymbolTable
{
    struct symtab_command symtabCommand;
    
    NSArray *symbols;
    NSUInteger baseAddress;
    
    NSDictionary *classSymbols;
    
    struct {
        unsigned int didFindBaseAddress:1;
        unsigned int didWarnAboutUnfoundBaseAddress:1;
    } flags;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        symtabCommand.cmd = [cursor readInt32];
        symtabCommand.cmdsize = [cursor readInt32];
        
        symtabCommand.symoff = [cursor readInt32];
        symtabCommand.nsyms = [cursor readInt32];
        symtabCommand.stroff = [cursor readInt32];
        symtabCommand.strsize = [cursor readInt32];
        
        // symoff is at the start of the first section (__pointers) of the __IMPORT segment
        // stroff falls within the __LINKEDIT segment
#if 0
        NSLog(@"symtab: %08x %08x  %08x %08x %08x %08x",
              symtabCommand.cmd, symtabCommand.cmdsize,
              symtabCommand.symoff, symtabCommand.nsyms, symtabCommand.stroff, symtabCommand.strsize);
        NSLog(@"data offset for stroff: %lu", [aMachOFile dataOffsetForAddress:symtabCommand.stroff]);
#endif
        
        symbols = nil;
        baseAddress = 0;
        
        classSymbols = nil;
        
        flags.didFindBaseAddress = NO;
        flags.didWarnAboutUnfoundBaseAddress = NO;
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)extraDescription;
{
    return [NSString stringWithFormat:@"symoff: 0x%08x (%u), nsyms: 0x%08x (%u), stroff: 0x%08x (%u), strsize: 0x%08x (%u)",
            symtabCommand.symoff, symtabCommand.symoff, symtabCommand.nsyms, symtabCommand.nsyms,
            symtabCommand.stroff, symtabCommand.stroff, symtabCommand.strsize, symtabCommand.strsize];
}

#pragma mark -

- (uint32_t)cmd;
{
    return symtabCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return symtabCommand.cmdsize;
}

#define CD_VM_PROT_RW (VM_PROT_READ|VM_PROT_WRITE)

- (void)loadSymbols;
{
    for (CDLoadCommand *loadCommand in [self.machOFile loadCommands]) {
        if ([loadCommand isKindOfClass:[CDLCSegment class]]) {
            CDLCSegment *segment = (CDLCSegment *)loadCommand;

            if (([segment initprot] & CD_VM_PROT_RW) == CD_VM_PROT_RW) {
                //NSLog(@"segment... initprot = %08x, addr= %016lx *** r/w", [segment initprot], [segment vmaddr]);
                baseAddress = [segment vmaddr];
                flags.didFindBaseAddress = YES;
                break;
            }
        }
    }
    
    NSMutableArray *_symbols = [[NSMutableArray alloc] init];
    NSMutableDictionary *_classSymbols = [[NSMutableDictionary alloc] init];

    CDMachOFileDataCursor *cursor = [[CDMachOFileDataCursor alloc] initWithFile:self.machOFile offset:symtabCommand.symoff];
    //NSLog(@"offset= %lu", [cursor offset]);
    //NSLog(@"stroff=  %lu", symtabCommand.stroff);
    //NSLog(@"strsize= %lu", symtabCommand.strsize);

    const char *strtab = [[self.machOFile machOData] bytes] + symtabCommand.stroff;

    if (![self.machOFile uses64BitABI]) {
        //NSLog(@"32 bit...");
        //NSLog(@"       str table index  type  sect  desc  value");
        //NSLog(@"       ---------------  ----  ----  ----  --------");
        for (uint32_t index = 0; index < symtabCommand.nsyms; index++) {
            struct nlist nlist;

            nlist.n_un.n_strx = [cursor readInt32];
            nlist.n_type = [cursor readByte];
            nlist.n_sect = [cursor readByte];
            nlist.n_desc = [cursor readInt16];
            nlist.n_value = [cursor readInt32];
#if 0
            NSLog(@"%5u: %08x           %02x    %02x  %04x  %08x - %s",
                  index, nlist.n_un.n_strx, nlist.n_type, nlist.n_sect, nlist.n_desc, nlist.n_value, strtab + nlist.n_un.n_strx);
#endif

            const char *ptr = strtab + nlist.n_un.n_strx;
            NSString *str = [[NSString alloc] initWithBytes:ptr length:strlen(ptr) encoding:NSASCIIStringEncoding];

            CDSymbol *symbol = [[CDSymbol alloc] initWithName:str machOFile:self.machOFile nlist32:nlist];
            [_symbols addObject:symbol];

            if ([str hasPrefix:ObjCClassSymbolPrefix] && symbol.value != 0) {
                NSString *className = [str substringFromIndex:[ObjCClassSymbolPrefix length]];
                [_classSymbols setObject:symbol forKey:className];
            }
        }

        //NSLog(@"Loaded %lu 32-bit symbols", [symbols count]);
    } else {
        //NSLog(@"       str table index  type  sect  desc  value");
        //NSLog(@"       ---------------  ----  ----  ----  ----------------");
        for (uint32_t index = 0; index < symtabCommand.nsyms; index++) {
            struct nlist_64 nlist;

            nlist.n_un.n_strx = [cursor readInt32];
            nlist.n_type = [cursor readByte];
            nlist.n_sect = [cursor readByte];
            nlist.n_desc = [cursor readInt16];
            nlist.n_value = [cursor readInt64];
#if 0
            NSLog(@"%5u: %08x           %02x    %02x  %04x  %016x - %s",
                  index, nlist.n_un.n_strx, nlist.n_type, nlist.n_sect, nlist.n_desc, nlist.n_value, strtab + nlist.n_un.n_strx);
#endif
            const char *ptr = strtab + nlist.n_un.n_strx;
            NSString *str = [[NSString alloc] initWithBytes:ptr length:strlen(ptr) encoding:NSASCIIStringEncoding];

            CDSymbol *symbol = [[CDSymbol alloc] initWithName:str machOFile:self.machOFile nlist64:nlist];
            [_symbols addObject:symbol];

            if ([str hasPrefix:ObjCClassSymbolPrefix] && symbol.value != 0) {
                NSString *className = [str substringFromIndex:[ObjCClassSymbolPrefix length]];
                [_classSymbols setObject:symbol forKey:className];
            }
        }

        //NSLog(@"Loaded %lu 64-bit symbols", [symbols count]);
    }
    
    symbols = [_symbols copy]; 
    classSymbols = [_classSymbols copy]; 

    //NSLog(@"symbols: %@", symbols);
}

- (uint32_t)symoff;
{
    return symtabCommand.symoff;
}

- (uint32_t)nsyms;
{
    return symtabCommand.nsyms;
}

- (uint32_t)stroff;
{
    return symtabCommand.stroff;
}

- (uint32_t)strsize;
{
    return symtabCommand.strsize;
}

- (NSUInteger)baseAddress;
{
    if (flags.didFindBaseAddress == NO && flags.didWarnAboutUnfoundBaseAddress == NO) {
        fprintf(stderr, "Warning: Couldn't find first read/write segment for base address of relocation entries.\n");
        flags.didWarnAboutUnfoundBaseAddress = YES;
    }

    return baseAddress;
}

- (NSArray *)symbols;
{
    return symbols;
}

- (CDSymbol *)symbolForClass:(NSString *)className;
{
    return [classSymbols objectForKey:className];
}

@end
