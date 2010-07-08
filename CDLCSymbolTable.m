// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDLCSymbolTable.h"

#include <mach-o/nlist.h>
#import "CDMachOFile.h"
#import "CDMachO32File.h"
#import "CDSymbol.h"
#import "CDLCSegment.h"

@implementation CDLCSymbolTable

- (id)initWithDataCursor:(CDDataCursor *)cursor machOFile:(CDMachOFile *)aMachOFile;
{
    if ([super initWithDataCursor:cursor machOFile:aMachOFile] == nil)
        return nil;

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

    symbols = [[NSMutableArray alloc] init];
    baseAddress = 0;

    classSymbols = [[NSMutableDictionary alloc] init];

    flags.didFindBaseAddress = NO;
    flags.didWarnAboutUnfoundBaseAddress = NO;

    return self;
}

- (void)dealloc;
{
    [symbols release];
    [classSymbols release];

    [super dealloc];
}

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
    CDDataCursor *cursor;
    uint32_t index;
    const char *strtab, *ptr;

    for (CDLoadCommand *loadCommand in [nonretained_machOFile loadCommands]) {
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


    cursor = [[CDDataCursor alloc] initWithData:[nonretained_machOFile data]];
    [cursor setByteOrder:[nonretained_machOFile byteOrder]];
    [cursor setOffset:[nonretained_machOFile offset] + symtabCommand.symoff];
    //NSLog(@"offset= %lu", [cursor offset]);
    //NSLog(@"stroff=  %lu", symtabCommand.stroff);
    //NSLog(@"strsize= %lu", symtabCommand.strsize);

    strtab = [nonretained_machOFile machODataBytes] + symtabCommand.stroff;

    if ([nonretained_machOFile isKindOfClass:[CDMachO32File class]]) {
        //NSLog(@"32 bit...");
        //NSLog(@"       str table index  type  sect  desc  value");
        //NSLog(@"       ---------------  ----  ----  ----  --------");
        for (index = 0; index < symtabCommand.nsyms; index++) {
            struct nlist nlist;
            CDSymbol *symbol;
            NSString *str;

            nlist.n_un.n_strx = [cursor readInt32];
            nlist.n_type = [cursor readByte];
            nlist.n_sect = [cursor readByte];
            nlist.n_desc = [cursor readInt16];
            nlist.n_value = [cursor readInt32];
#if 0
            NSLog(@"%5u: %08x           %02x    %02x  %04x  %08x - %s",
                  index, nlist.n_un.n_strx, nlist.n_type, nlist.n_sect, nlist.n_desc, nlist.n_value, strtab + nlist.n_un.n_strx);
#endif

            ptr = strtab + nlist.n_un.n_strx;
            str = [[NSString alloc] initWithBytes:ptr length:strlen(ptr) encoding:NSASCIIStringEncoding];

            symbol = [[CDSymbol alloc] initWithName:str machOFile:nonretained_machOFile nlist32:nlist];
            [symbols addObject:symbol];
            [symbol release];

            [str release];
        }

        //NSLog(@"Loaded %lu 32-bit symbols", [symbols count]);
    } else {
        //NSLog(@"       str table index  type  sect  desc  value");
        //NSLog(@"       ---------------  ----  ----  ----  ----------------");
        for (index = 0; index < symtabCommand.nsyms; index++) {
            struct nlist_64 nlist;
            CDSymbol *symbol;
            NSString *str;

            nlist.n_un.n_strx = [cursor readInt32];
            nlist.n_type = [cursor readByte];
            nlist.n_sect = [cursor readByte];
            nlist.n_desc = [cursor readInt16];
            nlist.n_value = [cursor readInt64];
#if 0
            NSLog(@"%5u: %08x           %02x    %02x  %04x  %016x - %s",
                  index, nlist.n_un.n_strx, nlist.n_type, nlist.n_sect, nlist.n_desc, nlist.n_value, strtab + nlist.n_un.n_strx);
#endif
            ptr = strtab + nlist.n_un.n_strx;
            str = [[NSString alloc] initWithBytes:ptr length:strlen(ptr) encoding:NSASCIIStringEncoding];

            symbol = [[CDSymbol alloc] initWithName:str machOFile:nonretained_machOFile nlist64:nlist];
            [symbols addObject:symbol];

            if ([str hasPrefix:ObjCClassSymbolPrefix] && [symbol value] != 0) {
                NSString *className = [str substringFromIndex:[ObjCClassSymbolPrefix length]];
                [classSymbols setObject:symbol forKey:className];
            }

            [symbol release];

            [str release];
        }

        //NSLog(@"Loaded %lu 64-bit symbols", [symbols count]);
    }

    [cursor release];

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

- (NSString *)extraDescription;
{
    return [NSString stringWithFormat:@"symoff: 0x%08x (%u), nsyms: 0x%08x (%u), stroff: 0x%08x (%u), strsize: 0x%08x (%u)",
                     symtabCommand.symoff, symtabCommand.symoff, symtabCommand.nsyms, symtabCommand.nsyms,
                     symtabCommand.stroff, symtabCommand.stroff, symtabCommand.strsize, symtabCommand.strsize];
}

@end
