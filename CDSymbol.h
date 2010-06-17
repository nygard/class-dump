// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import <Foundation/Foundation.h>

#include <mach-o/nlist.h>

extern NSString *const ObjCClassSymbolPrefix;

@interface CDSymbol : NSObject
{
    struct nlist_64 nlist;
    NSString *name;
}

- (id)initWithName:(NSString *)aName nlist32:(struct nlist)nlist32;
- (id)initWithName:(NSString *)aName nlist64:(struct nlist_64)nlist64;
- (void)dealloc;

- (uint8_t)type;
- (uint8_t)section;
- (uint16_t)desc;
- (uint64_t)value;

- (BOOL)isExported;

- (NSString *)name;
- (NSString *)description;

@end
