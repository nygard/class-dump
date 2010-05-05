// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDSymbolReferences, CDTypeController;

@interface CDOCMethod : NSObject <NSCopying>
{
    NSString *name;
    NSString *type;
    NSUInteger imp;

    BOOL hasParsedType;
    NSArray *parsedMethodTypes;
}

- (id)initWithName:(NSString *)aName type:(NSString *)aType imp:(NSUInteger)anImp;
- (id)initWithName:(NSString *)aName type:(NSString *)aType;
- (void)dealloc;

- (NSString *)name;
- (NSString *)type;

- (NSUInteger)imp;
- (void)setImp:(NSUInteger)newValue;

- (NSArray *)parsedMethodTypes;

- (NSString *)description;
- (void)appendToString:(NSMutableString *)resultString typeController:(CDTypeController *)typeController symbolReferences:(CDSymbolReferences *)symbolReferences;

- (NSComparisonResult)ascendingCompareByName:(CDOCMethod *)otherMethod;

- (id)copyWithZone:(NSZone *)zone;

@end
