// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2011 Steve Nygard.

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

- (NSString *)description;

@property (readonly) NSString *name;
@property (readonly) NSString *type;
@property (assign) NSUInteger imp;

- (NSArray *)parsedMethodTypes;

- (void)appendToString:(NSMutableString *)resultString typeController:(CDTypeController *)typeController symbolReferences:(CDSymbolReferences *)symbolReferences;

- (NSComparisonResult)ascendingCompareByName:(CDOCMethod *)otherMethod;

@end
