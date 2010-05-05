// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

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

    struct {
        unsigned int isReadOnly:1;
        unsigned int isDynamic:1;
    } flags;
}

- (id)initWithName:(NSString *)aName attributes:(NSString *)someAttributes;
- (void)dealloc;

- (NSString *)name;
- (NSString *)attributeString;
- (CDType *)type;
- (NSArray *)attributes;

- (NSString *)attributeStringAfterType;
- (void)_setAttributeStringAfterType:(NSString *)newValue;

- (NSString *)defaultGetter;
- (NSString *)defaultSetter;
- (NSString *)customGetter;
- (void)_setCustomGetter:(NSString *)newStr;
- (NSString *)customSetter;
- (void)_setCustomSetter:(NSString *)newStr;
- (NSString *)getter;
- (NSString *)setter;

- (BOOL)isReadOnly;
- (BOOL)isDynamic;

- (NSString *)description;

- (NSComparisonResult)ascendingCompareByName:(CDOCProperty *)otherProperty;

- (void)_parseAttributes;

@end
