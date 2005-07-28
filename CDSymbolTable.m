//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2004 Steve Nygard.  All rights reserved.

#import "CDSymbolTable.h"

#include <mach-o/nlist.h>
#import <Foundation/Foundation.h>
#import "CDMachOFile.h"
#import "CDSymbol.h"

@implementation CDSymbolTable

- (id)initWithPointer:(const void *)ptr machOFile:(CDMachOFile *)aMachOFile;
{
    if ([super initWithPointer:ptr machOFile:aMachOFile] == nil)
        return nil;

    symtabCommand = *(struct symtab_command *)ptr;
    symbols = [[NSMutableArray alloc] init];

    [self _process];

    //NSLog(@"self: %@", self);

    return self;
}

- (void)dealloc;
{
    [symbols release];

    [super dealloc];
}

- (void)_process;
{
    // TODO (2005-07-28): This needs to be converted to handle different byte orderings.
#if 0
    //const void *symtab;
    const struct nlist *symtab;
    const char *strtab;
    int index;

    NSLog(@" > %s", _cmd);
    NSLog(@"symoff: 0x%08x, nsyms: 0x%08x, stroff: 0x%08x, strsize: 0x%08x",
          symtabCommand.symoff, symtabCommand.nsyms, symtabCommand.stroff, symtabCommand.strsize);
    NSLog(@"symoff: %d, nsyms: %d, stroff: %d, strsize: %d",
          symtabCommand.symoff, symtabCommand.nsyms, symtabCommand.stroff, symtabCommand.strsize);

    symtab = [[self machOFile] bytesAtOffset:symtabCommand.symoff];
    NSLog(@"symtab: %p", symtab);

    strtab = [[self machOFile] bytesAtOffset:symtabCommand.stroff];
    NSLog(@"strtab: %p", strtab);

    // This will produce the same output as 'nm -axp <machofile>'
    for (index = 0; index < symtabCommand.nsyms; index++) {
        CDSymbol *aSymbol;
#if 0
        NSLog(@"n_strx: 0x%08x, n_type: 0x%02x, n_sect: 0x%02x, n_desc: 0x%04x, n_value: 0x%08x",
              symtab->n_un.n_strx, symtab->n_type, symtab->n_sect, symtab->n_desc, symtab->n_value);
        NSLog(@"n_strx: %s", strtab + symtab->n_un.n_strx);
#endif
        NSLog(@"%08x %02x %02x %04x %08x %s",
              symtab->n_value, symtab->n_type, symtab->n_sect, symtab->n_desc, symtab->n_un.n_strx, strtab + symtab->n_un.n_strx);

        aSymbol = [[CDSymbol alloc] initWithPointer:symtab symtab:&symtabCommand machOFile:[self machOFile]];
        [symbols addObject:aSymbol];
        [aSymbol release];

        symtab++;
    }

    NSLog(@"----------------------------------------");
    NSLog(@"symbols: %@", symbols);

    //NSLog(@"testing... %08x %08x %08x %08x", strtab[0], strtab[1], strtab[2], strtab[3]);

    NSLog(@"<  %s", _cmd);
#endif
}

- (unsigned long)symoff;
{
    return symtabCommand.symoff;
}

- (unsigned long)nsyms;
{
    return symtabCommand.nsyms;
}

- (unsigned long)stroff;
{
    return symtabCommand.stroff;
}

- (unsigned long)strsize;
{
    return symtabCommand.strsize;
}

- (NSString *)extraDescription;
{
    return [NSString stringWithFormat:@"symoff: 0x%08x (%d), nsyms: 0x%08x (%d), stroff: 0x%08x (%d), strsize: 0x%08x (%d)",
                     symtabCommand.symoff, symtabCommand.symoff, symtabCommand.nsyms, symtabCommand.nsyms,
                     symtabCommand.stroff, symtabCommand.stroff, symtabCommand.strsize, symtabCommand.strsize];
}

@end
