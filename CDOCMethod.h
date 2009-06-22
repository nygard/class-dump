// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2007  Steve Nygard

#import <Foundation/Foundation.h>

@class NSMutableString, NSString;
@class CDClassDump, CDSymbolReferences;

@interface CDOCMethod : NSObject <NSCopying>
{
    NSString *name;
    NSString *type;
    uint32_t imp;
}

- (id)initWithName:(NSString *)aName type:(NSString *)aType imp:(uint32_t)anImp;
- (id)initWithName:(NSString *)aName type:(NSString *)aType;
- (void)dealloc;

- (NSString *)name;
- (NSString *)type;

- (uint32_t)imp;
- (void)setImp:(uint32_t)newValue;

- (NSString *)description;
- (void)appendToString:(NSMutableString *)resultString classDump:(CDClassDump *)aClassDump symbolReferences:(CDSymbolReferences *)symbolReferences;

- (NSComparisonResult)ascendingCompareByName:(CDOCMethod *)otherMethod;

- (id)copyWithZone:(NSZone *)zone;

@end
