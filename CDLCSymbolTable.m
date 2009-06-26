// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

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
#if 1
    NSLog(@"symtab: %08x %08x  %08x %08x %08x %08x",
          symtabCommand.cmd, symtabCommand.cmdsize,
          symtabCommand.symoff, symtabCommand.nsyms, symtabCommand.stroff, symtabCommand.strsize);
    NSLog(@"data offset for stroff: %lu", [aMachOFile dataOffsetForAddress:symtabCommand.stroff]);
#endif

    symbols = [[NSMutableArray alloc] init];
    baseAddress = 0;

    //NSLog(@"self: %@", self);

    return self;
}

- (void)dealloc;
{
    [symbols release];

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
    BOOL didFindBaseAddress = NO;

    for (CDLoadCommand *loadCommand in [nonretainedMachOFile loadCommands]) {
        if ([loadCommand isKindOfClass:[CDLCSegment class]]) {
            CDLCSegment *segment = (CDLCSegment *)loadCommand;

            if (([segment initprot] & CD_VM_PROT_RW) == CD_VM_PROT_RW) {
                NSLog(@"segment... initprot = %08x, addr= %016lx *** r/w", [segment initprot], [segment vmaddr]);
                baseAddress = [segment vmaddr];
                didFindBaseAddress = YES;
                break;
            }
        }
    }

    if (didFindBaseAddress == NO)
        NSLog(@"Warning: Couldn't find first read/write segment for base address of relocation entries.");

    cursor = [[CDDataCursor alloc] initWithData:[nonretainedMachOFile data]];
    [cursor setByteOrder:[nonretainedMachOFile byteOrder]];
    [cursor setOffset:symtabCommand.symoff]; // TODO: + file offset for fat files?
    //NSLog(@"offset= %lu", [cursor offset]);
    //NSLog(@"stroff=  %lu", symtabCommand.stroff);
    //NSLog(@"strsize= %lu", symtabCommand.strsize);

    strtab = [[nonretainedMachOFile data] bytes] + symtabCommand.stroff;

    if ([nonretainedMachOFile isKindOfClass:[CDMachO32File class]]) {
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

            symbol = [[CDSymbol alloc] initWithName:str nlist32:nlist];
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

            symbol = [[CDSymbol alloc] initWithName:str nlist64:nlist];
            [symbols addObject:symbol];
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

- (NSString *)extraDescription;
{
    return [NSString stringWithFormat:@"symoff: 0x%08x (%u), nsyms: 0x%08x (%u), stroff: 0x%08x (%u), strsize: 0x%08x (%u)",
                     symtabCommand.symoff, symtabCommand.symoff, symtabCommand.nsyms, symtabCommand.nsyms,
                     symtabCommand.stroff, symtabCommand.stroff, symtabCommand.strsize, symtabCommand.strsize];
}

@end
