// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDSymbolReferences, CDType;

@interface CDTypeFormatter : NSObject
{
    NSUInteger baseLevel;

    struct {
        unsigned int shouldExpand:1; // But just top level struct, level == 0
        unsigned int shouldAutoExpand:1;
        unsigned int shouldShowLexing:1;
    } flags;

    // Not ideal
    id nonretainedDelegate;
}

@property NSUInteger baseLevel;
@property BOOL shouldExpand;
@property BOOL shouldAutoExpand;
@property BOOL shouldShowLexing;

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

- (NSString *)_specialCaseVariable:(NSString *)name type:(NSString *)type;
- (NSString *)_specialCaseVariable:(NSString *)name parsedType:(CDType *)type;

- (NSString *)formatVariable:(NSString *)name type:(NSString *)type symbolReferences:(CDSymbolReferences *)symbolReferences;
- (NSString *)formatVariable:(NSString *)name parsedType:(CDType *)type symbolReferences:(CDSymbolReferences *)symbolReferences;

- (NSDictionary *)formattedTypesForMethodName:(NSString *)methodName type:(NSString *)type symbolReferences:(CDSymbolReferences *)symbolReferences;
- (NSString *)formatMethodName:(NSString *)methodName type:(NSString *)type symbolReferences:(CDSymbolReferences *)symbolReferences;

- (CDType *)replacementForType:(CDType *)aType;
- (NSString *)typedefNameForStruct:(CDType *)structType level:(NSUInteger)level;

@end
