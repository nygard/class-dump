//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2005  Steve Nygard

#import "CDTypeParser.h"

#include <assert.h>
#import <Foundation/Foundation.h>
#import "CDMethodType.h"
#import "CDType.h"
#import "CDTypeName.h"
#import "CDTypeLexer.h"
#import "NSString-Extensions.h"

NSString *CDSyntaxError = @"Syntax Error";

NSString *CDTokenDescription(int token)
{
    if (token < 128)
        return [NSString stringWithFormat:@"%d(%c)", token, token];

    return [NSString stringWithFormat:@"%d", token];
}

@implementation CDTypeParser

- (id)initWithType:(NSString *)aType;
{
    if ([super init] == nil)
        return nil;

    lexer = [[CDTypeLexer alloc] initWithString:aType];
    lookahead = 0;

    return self;
}

- (void)dealloc;
{
    [lexer release];

    [super dealloc];
}

- (CDTypeLexer *)lexer;
{
    return lexer;
}

- (NSArray *)parseMethodType;
{
    NSArray *result;

    NS_DURING {
        lookahead = [lexer scanNextToken];
        result = [self _parseMethodType];
    } NS_HANDLER {
        NSLog(@"caught exception: %@", localException);
        NSLog(@"type: %@", [lexer string]);
        NSLog(@"remaining string: %@", [lexer remainingString]);

        result = nil;
    } NS_ENDHANDLER;

    return result;
}

- (CDType *)parseType;
{
    CDType *result;

    NS_DURING {
        lookahead = [lexer scanNextToken];
        result = [self _parseType];
    } NS_HANDLER {
        NSLog(@"caught exception: %@", localException);
        NSLog(@"type: %@", [lexer string]);
        NSLog(@"remaining string: %@", [lexer remainingString]);

        result = nil;
    } NS_ENDHANDLER;

    return result;
}

@end

@implementation CDTypeParser (Private)

- (void)match:(int)token;
{
    [self match:token enterState:[lexer state]];
}

- (void)match:(int)token enterState:(int)newState;
{
    if (lookahead == token) {
        //NSLog(@"matched %@", CDTokenDescription(token));
        [lexer setState:newState];
        lookahead = [lexer scanNextToken];
    } else {
        [NSException raise:CDSyntaxError format:@"expected token %@, got %@",
                     CDTokenDescription(token),
                     CDTokenDescription(lookahead)];
    }
}

- (void)error:(NSString *)errorString;
{
    [NSException raise:CDSyntaxError format:@"%@", errorString];
}

- (NSArray *)_parseMethodType;
{
    NSMutableArray *methodTypes;
    CDMethodType *aMethodType;
    CDType *type;
    NSString *number;

    methodTypes = [NSMutableArray array];

    // Has to have at least one pair for the return type;
    // Probably needs at least two more, for object and selector

    do {
        type = [self _parseType];
        number = [self parseNumber];

        aMethodType = [[CDMethodType alloc] initWithType:type offset:number];
        [methodTypes addObject:aMethodType];
        [aMethodType release];
    } while ([self isLookaheadInTypeStartSet] == YES);

    return methodTypes;
}

// Plain object types can be:
//     @                     - plain id type
//     @"NSObject"           - NSObject *
//     @"<MyProtocol>"       - id <MyProtocol>
// But these can also be part of a structure, with the member name in quotes before the type:
//     i"foo"                - int foo
//     @"foo"                - id foo
//     @"Foo"                - Foo *
// So this is where the class name heuristics are used.  I think.  Maybe.
//
// I'm going to make a simplifying assumption:  Either the structure/union has member names,
// or is doesn't, it can't have some names and be missing others.
// The two key tests are:
//     {my_struct3="field1"@"field2"i}
//     {my_struct4="field1"@"NSObject""field2"i}
//
// Hmm.  I think having the lexer have a quoted string token would make the lookahead easier.

- (CDType *)_parseType;
{
    CDType *result;

    if (lookahead == 'r'
        || lookahead == 'n'
        || lookahead == 'N'
        || lookahead == 'o'
        || lookahead == 'O'
        || lookahead == 'R'
        || lookahead == 'V') { // modifiers
        int modifier;
        CDType *unmodifiedType;
        modifier = lookahead;
        [self match:modifier];

        if ([self isLookaheadInTypeStartSet] == YES)
            unmodifiedType = [self _parseType];
        else
            unmodifiedType = nil;
        result = [[CDType alloc] initModifier:modifier type:unmodifiedType];
    } else if (lookahead == '^') { // pointer
        CDType *type;

        [self match:'^'];
        type = [self _parseType];
        result = [[CDType alloc] initPointerType:type];
    } else if (lookahead == 'b') { // bitfield
        NSString *number;

        [self match:'b'];
        number = [self parseNumber];
        result = [[CDType alloc] initBitfieldType:number];
    } else if (lookahead == '@') { // id
        [self match:'@'];

        if (lookahead == TK_QUOTED_STRING && ([[lexer scanner] isAtEnd] || [lexer peekChar] == '"')) {
            NSString *str;
            CDTypeName *typeName;

            str = [lexer lexText];
            if ([str hasPrefix:@"<"] == YES && [str hasSuffix:@">"] == YES) {
                str = [str substringWithRange:NSMakeRange(1, [str length] - 2)];
                result = [[CDType alloc] initIDTypeWithProtocols:str];
            } else {
                typeName = [[CDTypeName alloc] init];
                [typeName setName:str];
                result = [[CDType alloc] initIDType:typeName];
                [typeName release];
            }

            [self match:TK_QUOTED_STRING];
        } else {
            result = [[CDType alloc] initIDType:nil];
        }
    } else if (lookahead == '{') { // structure
        CDTypeName *typeName;
        NSArray *optionalMembers;
        CDTypeLexerState savedState;

        savedState = [lexer state];
        [self match:'{' enterState:CDTypeLexerStateIdentifier];
        typeName = [self parseTypeName];
        optionalMembers = [self parseOptionalMembers];
        [self match:'}' enterState:savedState];

        result = [[CDType alloc] initStructType:typeName members:optionalMembers];
    } else if (lookahead == '(') { // union
        CDTypeLexerState savedState;

        savedState = [lexer state];
        [self match:'(' enterState:CDTypeLexerStateIdentifier];
        if (lookahead == TK_IDENTIFIER) {
            CDTypeName *typeName;
            NSArray *optionalMembers;

            typeName = [self parseTypeName];
            optionalMembers = [self parseOptionalMembers];
            [self match:')' enterState:savedState];

            result = [[CDType alloc] initUnionType:typeName members:optionalMembers];
        } else {
            NSArray *unionTypes;

            unionTypes = [self parseUnionTypes];
            [self match:')' enterState:savedState];

            result = [[CDType alloc] initUnionType:nil members:unionTypes];
        }
    } else if (lookahead == '[') { // array
        NSString *number;
        CDType *type;

        [self match:'['];
        number = [self parseNumber];
        type = [self _parseType];
        [self match:']'];

        result = [[CDType alloc] initArrayType:type count:number];
    } else if ([self isLookaheadInSimpleTypeSet] == YES) { // simple type
        int simpleType;

        simpleType = lookahead;
        [self match:simpleType];
        result = [[CDType alloc] initSimpleType:simpleType];
    } else {
        result = nil;
        [NSException raise:CDSyntaxError format:@"expected (many things), got %d", lookahead];
    }

    return [result autorelease];
}

// This seems to be used in method types -- no names
- (NSArray *)parseUnionTypes;
{
    NSMutableArray *members;

    members = [NSMutableArray array];

    while ([self isLookaheadInTypeSet] == YES) {
        CDType *aType;

        aType = [self _parseType];
        //[aType setVariableName:@"___"];
        [members addObject:aType];
    }

    return members;
}

- (NSArray *)parseOptionalMembers;
{
    NSArray *result;

    if (lookahead == '=') {
        [self match:'='];
        result = [self parseMemberList];
    } else
        result = nil;

    return result;
}

- (NSArray *)parseMemberList;
{
    NSMutableArray *result;

    result = [NSMutableArray array];
    while (lookahead == TK_QUOTED_STRING || [self isLookaheadInTypeSet] == YES) {
        [result addObject:[self parseMember]];
    }

    return result;
}

- (CDType *)parseMember;
{
    CDType *result;

    if (lookahead == TK_QUOTED_STRING) {
        NSString *identifier;

        identifier = [lexer lexText];
        [self match:TK_QUOTED_STRING];

        result = [self _parseType];
        [result setVariableName:identifier];
    } else {
        result = [self _parseType];
        //[result setVariableName:@"___"];
    }

    return result;
}

- (CDTypeName *)parseTypeName;
{
    CDTypeName *typeName;

    typeName = [[[CDTypeName alloc] init] autorelease];
    [typeName setName:[self parseIdentifier]];

    if (lookahead == '<') {
        CDTypeLexerState savedState;

        savedState = [lexer state];
        [self match:'<' enterState:CDTypeLexerStateTemplateTypes];
        [typeName addTemplateType:[self parseTypeName]];
        while (lookahead == ',') {
            [self match:','];
            [typeName addTemplateType:[self parseTypeName]];
        }

        // iPhoto 5 has types like.... vector<foo,bar<blegga> >  -- note the extra space
        // Also, std::pair<const double, int>
        [self match:'>' enterState:savedState];
    }

    return typeName;
}

- (NSString *)parseIdentifier;
{
    if (lookahead == TK_IDENTIFIER) {
        NSString *result;

        result = [lexer lexText];
        [self match:TK_IDENTIFIER];
        return result;
    }

    return nil;
}

- (NSString *)parseNumber;
{
    if (lookahead == TK_NUMBER) {
        NSString *result;

        result = [lexer lexText];
        [self match:TK_NUMBER];
        return result;
    }

    return nil;
}

- (BOOL)isLookaheadInModifierSet;
{
    if (lookahead == 'r'
        || lookahead == 'n'
        || lookahead == 'N'
        || lookahead == 'o'
        || lookahead == 'O'
        || lookahead == 'R'
        || lookahead == 'V')
        return YES;

    return NO;
}

- (BOOL)isLookaheadInSimpleTypeSet;
{
    if (lookahead == 'c'
        || lookahead == 'i'
        || lookahead == 's'
        || lookahead == 'l'
        || lookahead == 'q'
        || lookahead == 'C'
        || lookahead == 'I'
        || lookahead == 'S'
        || lookahead == 'L'
        || lookahead == 'Q'
        || lookahead == 'f'
        || lookahead == 'd'
        || lookahead == 'B'
        || lookahead == 'v'
        || lookahead == '*'
        || lookahead == '#'
        || lookahead == ':'
        || lookahead == '%'
        || lookahead == '?')
        return YES;

    return NO;
}

- (BOOL)isLookaheadInTypeSet;
{
    if ([self isLookaheadInModifierSet] == YES
        || [self isLookaheadInSimpleTypeSet] == YES
        || lookahead == '^'
        || lookahead == 'b'
        || lookahead == '@'
        || lookahead == '{'
        || lookahead == '('
        || lookahead == '[')
        return YES;

    return NO;
}

- (BOOL)isLookaheadInTypeStartSet;
{
    if (lookahead == 'r'
        || lookahead == 'n'
        || lookahead == 'N'
        || lookahead == 'o'
        || lookahead == 'O'
        || lookahead == 'R'
        || lookahead == 'V'
        || lookahead == '^'
        || lookahead == 'b'
        || lookahead == '@'
        || lookahead == '{'
        || lookahead == '('
        || lookahead == '['
        || [self isLookaheadInSimpleTypeSet] == YES)
        return YES;

    return NO;
}

@end
