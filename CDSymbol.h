// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import <Foundation/Foundation.h>

#include <mach-o/nlist.h>

extern NSString *const ObjCClassSymbolPrefix;

@class CDMachOFile;

@interface CDSymbol : NSObject
{
    struct nlist_64 nlist;
    BOOL is32Bit;
    NSString *name;
    CDMachOFile *nonretained_machOFile;
}

- (id)initWithName:(NSString *)aName machOFile:(CDMachOFile *)aMachOFile nlist32:(struct nlist)nlist32;
- (id)initWithName:(NSString *)aName machOFile:(CDMachOFile *)aMachOFile nlist64:(struct nlist_64)nlist64;
- (void)dealloc;

- (uint64_t)value;
- (NSString *)name;

- (BOOL)isExternal;

- (NSComparisonResult)compare:(CDSymbol *)aSymbol;
- (NSComparisonResult)nameCompare:(CDSymbol *)aSymbol;

- (NSString *)description;

@end
