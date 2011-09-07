// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2011 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDType;

@interface CDOCProperty : NSObject
{
    NSString *name;
    NSString *attributeString;

    CDType *type;
    NSMutableArray *attributes;

    BOOL hasParsedAttributes;
    NSString *attributeStringAfterType;
    NSString *customGetter;
    NSString *customSetter;

    BOOL isReadOnly;
    BOOL isDynamic;
}

- (id)initWithName:(NSString *)aName attributes:(NSString *)someAttributes;

- (NSString *)description;

@property (readonly) NSString *name;
@property (readonly) NSString *attributeString;
@property (readonly) CDType *type;
@property (readonly) NSArray *attributes;

@property (retain) NSString *attributeStringAfterType;

@property (readonly) NSString *defaultGetter;
@property (readonly) NSString *defaultSetter;

@property (retain) NSString *customGetter;
@property (retain) NSString *customSetter;

@property (readonly) NSString *getter;
@property (readonly) NSString *setter;

@property (readonly) BOOL isReadOnly;
@property (readonly) BOOL isDynamic;

- (NSComparisonResult)ascendingCompareByName:(CDOCProperty *)otherProperty;

- (void)_parseAttributes;

@end
