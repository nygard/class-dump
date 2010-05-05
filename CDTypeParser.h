// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDMethodType, CDType, CDTypeLexer, CDTypeName;

extern NSString *CDSyntaxError;
extern NSString *CDTypeParserErrorDomain;

#define CDTypeParserCodeDefault 0
#define CDTypeParserCodeSyntaxError 1

@interface CDTypeParser : NSObject
{
    CDTypeLexer *lexer;
    int lookahead;
}

- (id)initWithType:(NSString *)aType;
- (void)dealloc;

- (CDTypeLexer *)lexer;

- (NSArray *)parseMethodType:(NSError **)error;
- (CDType *)parseType:(NSError **)error;

@end

@interface CDTypeParser (Private)

- (void)match:(int)token;
- (void)match:(int)token enterState:(int)newState;
- (void)error:(NSString *)errorString;

- (NSArray *)_parseMethodType;
- (CDType *)_parseType;
- (CDType *)_parseTypeInStruct:(BOOL)isInStruct;

- (NSArray *)parseUnionTypes;
- (NSArray *)parseOptionalMembers;
- (NSArray *)parseMemberList;
- (CDType *)parseMember;

- (CDTypeName *)parseTypeName;
- (NSString *)parseIdentifier;
- (NSString *)parseNumber;

- (BOOL)isTokenInModifierSet:(int)aToken;
- (BOOL)isTokenInSimpleTypeSet:(int)aToken;
- (BOOL)isTokenInTypeSet:(int)aToken;
- (BOOL)isTokenInTypeStartSet:(int)aToken;

@end
