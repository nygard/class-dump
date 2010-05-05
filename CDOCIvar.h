// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDSymbolReferences, CDType, CDTypeController;

@interface CDOCIvar : NSObject
{
    NSString *name;
    NSString *type;
    NSUInteger offset;

    BOOL hasParsedType;
    CDType *parsedType;
}

- (id)initWithName:(NSString *)aName type:(NSString *)aType offset:(NSUInteger)anOffset;
- (void)dealloc;

- (NSString *)name;
- (NSString *)type;
- (NSUInteger)offset;

- (CDType *)parsedType;

- (NSString *)description;
- (void)appendToString:(NSMutableString *)resultString typeController:(CDTypeController *)typeController symbolReferences:(CDSymbolReferences *)symbolReferences;

@end
