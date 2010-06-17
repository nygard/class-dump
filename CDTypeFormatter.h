// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDSymbolReferences, CDType, CDTypeController;

@interface CDTypeFormatter : NSObject
{
    id nonretained_typeController;

    NSUInteger baseLevel;

    struct {
        unsigned int shouldExpand:1; // But just top level struct, level == 0
        unsigned int shouldAutoExpand:1;
        unsigned int shouldShowLexing:1;
    } flags;
}

@property NSUInteger baseLevel;
@property BOOL shouldExpand;
@property BOOL shouldAutoExpand;
@property BOOL shouldShowLexing;

- (CDTypeController *)typeController;
- (void)setTypeController:(CDTypeController *)newTypeController;

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
