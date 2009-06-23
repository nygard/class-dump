// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import "CDSymbol.h"

#import <mach-o/nlist.h>
#import <mach-o/loader.h>
#import <Foundation/Foundation.h>
#import "CDMachOFile.h"

@implementation CDSymbol

- (id)initWithPointer:(const void *)ptr symtab:(const struct symtab_command *)symtabCommand machOFile:(CDMachOFile *)aMachOFile;
{
    const char *str;

    if ([super init] == nil)
        return nil;

    nlist = ptr;
    str = [aMachOFile bytesAtOffset:symtabCommand->stroff + nlist->n_un.n_strx];

    // TODO (2004-07-08): Not sure of the encoding, UTF-8 might not work.
    name = [[NSString alloc] initWithUTF8String:str];

    return self;
}

- (void)dealloc;
{
    [name release];

    [super dealloc];
}

- (long)strx;
{
    return nlist->n_type;
}

- (unsigned char)type;
{
    return nlist->n_type;
}

- (unsigned char)section;
{
    return nlist->n_sect;
}

- (short)desc;
{
    return nlist->n_desc;
}

- (unsigned long)value;
{
    return nlist->n_value;
}

- (NSString *)name;
{
    return name;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"%08x %02x %02x %04x %08x %@",
                     nlist->n_value, nlist->n_type, nlist->n_sect, nlist->n_desc, nlist->n_un.n_strx, name];
}

@end
