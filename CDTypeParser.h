//
// $Id: CDTypeParser.h,v 1.12 2004/01/06 01:51:57 nygard Exp $
//

//  This file is part of class-dump, a utility for exmaing the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import <Foundation/NSObject.h>
//#include "datatypes.h"

@class NSArray, NSString;
@class CDMethodType, CDType, CDTypeLexer;

extern NSString *CDSyntaxError;

@interface CDTypeParser : NSObject
{
    CDTypeLexer *lexer;
    int lookahead;
}

- (id)initWithType:(NSString *)aType;
- (void)dealloc;

// TODO (2003-12-18): Or add subclass, CDMethodTypeParser, and then just have them -parse?  Nah, different return types.
- (NSArray *)parseMethodType;
- (CDType *)parseType;

@end

@interface CDTypeParser (Private)

- (void)match:(int)token;
- (void)match:(int)token allowIdentifier:(BOOL)shouldAllowIdentifier;
- (void)error:(NSString *)errorString;

- (NSArray *)_parseMethodType;
- (CDType *)_parseType;
- (CDType *)_parseTypeUseClassNameHeuristics:(BOOL)shouldUseHeuristics;

- (NSArray *)parseUnionTypes;
- (NSArray *)parseOptionalMembers;
- (NSArray *)parseMemberList;
- (CDType *)parseMember;

- (NSString *)parseTypeName;
- (NSString *)parseIdentifier;
- (NSString *)parseNumber;
- (NSString *)parseQuotedName;

- (BOOL)isLookaheadInModifierSet;
- (BOOL)isLookaheadInSimpleTypeSet;
- (BOOL)isLookaheadInTypeSet;
- (BOOL)isLookaheadInTypeStartSet;

@end
