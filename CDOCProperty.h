// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDType;

@interface CDOCProperty : NSObject
{
    NSString *name;
    NSString *attributeString;

    BOOL hasParsedAttributes;
    CDType *type;
    NSMutableArray *attributes;
}

- (id)initWithName:(NSString *)aName attributes:(NSString *)someAttributes;
- (void)dealloc;

- (NSString *)name;
- (NSString *)attributeString;
- (CDType *)type;
- (NSArray *)attributes;

- (NSString *)description;

- (NSComparisonResult)ascendingCompareByName:(CDOCProperty *)otherProperty;

- (void)parseAttributes;

@end
