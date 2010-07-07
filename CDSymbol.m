// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDSymbol.h"

#import <mach-o/nlist.h>
#import <mach-o/loader.h>
#import "CDMachOFile.h"

NSString *const ObjCClassSymbolPrefix = @"_OBJC_CLASS_$_";

@implementation CDSymbol

- (id)initWithName:(NSString *)aName nlist32:(struct nlist)nlist32;
{
    if ([super init] == nil)
        return nil;

    is32Bit = YES;
    name = [aName retain];
    nlist.n_un.n_strx = 0; // We don't use it.
    nlist.n_type = nlist32.n_type;
    nlist.n_sect = nlist32.n_sect;
    nlist.n_desc = nlist32.n_desc;
    nlist.n_value = nlist32.n_value;

    return self;
}

- (id)initWithName:(NSString *)aName nlist64:(struct nlist_64)nlist64;
{
    if ([super init] == nil)
        return nil;

    is32Bit = NO;
    name = [aName retain];
    nlist.n_un.n_strx = 0; // We don't use it.
    nlist.n_type = nlist64.n_type;
    nlist.n_sect = nlist64.n_sect;
    nlist.n_desc = nlist64.n_desc;
    nlist.n_value = nlist64.n_value;

    return self;
}

- (void)dealloc;
{
    [name release];

    [super dealloc];
}

- (uint8_t)type;
{
    return nlist.n_type;
}

- (uint8_t)section;
{
    return nlist.n_sect;
}

- (uint16_t)desc;
{
    return nlist.n_desc;
}

- (uint64_t)value;
{
    return nlist.n_value;
}

- (BOOL)isExported;
{
    return (nlist.n_type & N_EXT) == N_EXT;
}

- (NSString *)name;
{
    return name;
}

- (NSString *)description;
{
    NSString *valueFormat = [NSString stringWithFormat:@"%%0%ullx", is32Bit ? 8 : 16];
    return [NSString stringWithFormat:[valueFormat stringByAppendingString:@" %02x %02x %04x - %@"],
                     nlist.n_value, nlist.n_type, nlist.n_sect, nlist.n_desc, name];
}

@end
