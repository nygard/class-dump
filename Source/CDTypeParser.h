// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import <Foundation/Foundation.h>

#import "CDTypeLexer.h" // For CDTypeLexerState

@class CDMethodType, CDType, CDTypeLexer, CDTypeName;

extern NSString *CDExceptionName_SyntaxError;
extern NSString *CDErrorDomain_TypeParser;

extern NSString *CDErrorKey_Type;
extern NSString *CDErrorKey_RemainingString;
extern NSString *CDErrorKey_MethodOrVariable;
extern NSString *CDErrorKey_LocalizedLongDescription;

#define CDTypeParserCode_Default 0
#define CDTypeParserCode_SyntaxError 1

@interface CDTypeParser : NSObject

- (id)initWithType:(NSString *)aType;
- (void)dealloc;

@property (readonly) CDTypeLexer *lexer;

- (NSArray *)parseMethodType:(NSError **)error;
- (CDType *)parseType:(NSError **)error;

@end

@interface CDTypeParser (Private)

- (void)match:(int)token;
- (void)match:(int)token enterState:(CDTypeLexerState)newState;
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
