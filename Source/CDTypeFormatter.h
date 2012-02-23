// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDSymbolReferences, CDType, CDTypeController;

@interface CDTypeFormatter : NSObject

@property (assign) NSUInteger baseLevel;
@property (assign) BOOL shouldExpand;
@property (assign) BOOL shouldAutoExpand;
@property (assign) BOOL shouldShowLexing;

@property (assign) CDTypeController *typeController;

- (NSString *)_specialCaseVariable:(NSString *)name type:(NSString *)type;
- (NSString *)_specialCaseVariable:(NSString *)name parsedType:(CDType *)type;

- (NSString *)formatVariable:(NSString *)name type:(NSString *)type symbolReferences:(CDSymbolReferences *)symbolReferences;
- (NSString *)formatVariable:(NSString *)name parsedType:(CDType *)type symbolReferences:(CDSymbolReferences *)symbolReferences;

- (NSDictionary *)formattedTypesForMethodName:(NSString *)methodName type:(NSString *)type symbolReferences:(CDSymbolReferences *)symbolReferences;
- (NSString *)formatMethodName:(NSString *)methodName type:(NSString *)type symbolReferences:(CDSymbolReferences *)symbolReferences;

- (CDType *)replacementForType:(CDType *)aType;
- (NSString *)typedefNameForStruct:(CDType *)structType level:(NSUInteger)level;

- (NSString *)description;

@end
