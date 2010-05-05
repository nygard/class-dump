// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDTypeParser.h"

#include <assert.h>
#import "CDMethodType.h"
#import "CDType.h"
#import "CDTypeName.h"
#import "CDTypeLexer.h"
#import "NSString-Extensions.h"

NSString *CDSyntaxError = @"Syntax Error";
NSString *CDTypeParserErrorDomain = @"CDTypeParserErrorDomain";

static BOOL debug = NO;

static NSString *CDTokenDescription(int token)
{
    if (token < 128)
        return [NSString stringWithFormat:@"%d(%c)", token, token];

    return [NSString stringWithFormat:@"%d", token];
}

@implementation CDTypeParser

- (id)initWithType:(NSString *)aType;
{
    NSMutableString *str;

    if ([super init] == nil)
        return nil;

    // Do some preprocessing first: Replace "<unnamed>::" with just "unnamed::".
    str = [aType mutableCopy];
    [str replaceOccurrencesOfString:@"<unnamed>::" withString:@"unnamed::" options:0 range:NSMakeRange(0, [aType length])];

    lexer = [[CDTypeLexer alloc] initWithString:str];
    lookahead = 0;

    [str release];

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

- (NSArray *)parseMethodType:(NSError **)error;
{
    NSArray *result;

    *error = nil;

    @try {
        lookahead = [lexer scanNextToken];
        result = [self _parseMethodType];
    }
    @catch (NSException *exception) {
        NSDictionary *userInfo;
        int code;

        // Obviously I need to figure out a sane method of dealing with errors here.  This is not.
        if ([[exception name] isEqual:CDSyntaxError]) {
            code = CDTypeParserCodeSyntaxError;
            userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:@"Syntax Error", @"reason",
                                             [NSString stringWithFormat:@"Syntax Error, %@:\n\t     type: %@\n\tremaining: %@",
                                                       [exception reason], [lexer string], [lexer remainingString]], @"explanation",
                                             [lexer string], @"type",
                                             [lexer remainingString], @"remaining string",
                                             nil];
        } else {
            code = CDTypeParserCodeDefault;
            userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:[exception reason], @"reason",
                                             [lexer string], @"type",
                                             [lexer remainingString], @"remaining string",
                                             nil];
        }
        *error = [NSError errorWithDomain:CDTypeParserErrorDomain code:code userInfo:userInfo];
        [userInfo release];

        result = nil;
    }

    return result;
}

- (CDType *)parseType:(NSError **)error;
{
    CDType *result;

    *error = nil;

    @try {
        lookahead = [lexer scanNextToken];
        result = [self _parseType];
    }
    @catch (NSException *exception) {
        NSDictionary *userInfo;
        int code;

        // Obviously I need to figure out a sane method of dealing with errors here.  This is not.
        if ([[exception name] isEqual:CDSyntaxError]) {
            code = CDTypeParserCodeSyntaxError;
            userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:@"Syntax Error", @"reason",
                                             [NSString stringWithFormat:@"%@:\n\t     type: %@\n\tremaining: %@",
                                                       [exception reason], [lexer string], [lexer remainingString]], @"explanation",
                                             [lexer string], @"type",
                                             [lexer remainingString], @"remaining string",
                                             nil];
        } else {
            code = CDTypeParserCodeDefault;
            userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:[exception reason], @"reason",
                                             [lexer string], @"type",
                                             [lexer remainingString], @"remaining string",
                                             nil];
        }
        *error = [NSError errorWithDomain:CDTypeParserErrorDomain code:code userInfo:userInfo];
        [userInfo release];

        result = nil;
    }

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
        if (debug) NSLog(@"matched %@", CDTokenDescription(token));
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
    // So it must be <type><number><type><number><type><number>.  Three pairs at a minimum.

    do {
        type = [self _parseType];
        number = [self parseNumber];

        aMethodType = [[CDMethodType alloc] initWithType:type offset:number];
        [methodTypes addObject:aMethodType];
        [aMethodType release];
    } while ([self isTokenInTypeStartSet:lookahead]);

    return methodTypes;
}

// Plain object types can be:
//     @                     - plain id type
//     @"NSObject"           - NSObject *
//     @"<MyProtocol>"       - id <MyProtocol>
// But these can also be part of a structure, with the field name in quotes before the type:
//     "foo"i"bar"i                - int foo, int bar
//     "foo"@"bar"i                - id foo, int bar
//     "foo"@"Foo""bar"i           - Foo *foo, int bar
// So this is where we need to be careful.
//
// I'm going to make a simplifying assumption:  Either the structure/union has member names,
// or is doesn't, it can't have some names and be missing others.
// The two key tests are:
//     {my_struct3="field1"@"field2"i}
//     {my_struct4="field1"@"NSObject""field2"i}

- (CDType *)_parseType;
{
    return [self _parseTypeInStruct:NO];
}

- (CDType *)_parseTypeInStruct:(BOOL)isInStruct;
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

        if ([self isTokenInTypeStartSet:lookahead])
            unmodifiedType = [self _parseTypeInStruct:isInStruct];
        else
            unmodifiedType = nil;
        result = [[CDType alloc] initModifier:modifier type:unmodifiedType];
    } else if (lookahead == '^') { // pointer
        CDType *type;

        [self match:'^'];
        if (lookahead == TK_QUOTED_STRING || lookahead == '}' || lookahead == ')') {
            type = [[CDType alloc] initSimpleType:'v'];
            // Safari on 10.5 has: "m_function"{?="__pfn"^"__delta"i}
            result = [[CDType alloc] initPointerType:type];
            [type release];
        } else {
            type = [self _parseTypeInStruct:isInStruct];
            result = [[CDType alloc] initPointerType:type];
        }
    } else if (lookahead == 'b') { // bitfield
        NSString *number;

        [self match:'b'];
        number = [self parseNumber];
        result = [[CDType alloc] initBitfieldType:number];
    } else if (lookahead == '@') { // id
        [self match:'@'];
#if 0
        if (lookahead == TK_QUOTED_STRING) {
            NSLog(@"%s, quoted string ahead, shouldCheckFieldNames: %d, end: %d",
                  _cmd, shouldCheckFieldNames, [[lexer scanner] isAtEnd]);
            if ([[lexer scanner] isAtEnd] == NO)
                NSLog(@"next character: %d (%c), isInTypeStartSet: %d", [lexer peekChar], [lexer peekChar], [self isTokenInTypeStartSet:[lexer peekChar]]);
        }
#endif
        if (lookahead == TK_QUOTED_STRING && (isInStruct == NO || [[lexer lexText] isFirstLetterUppercase] || [self isTokenInTypeStartSet:[lexer peekChar]] == NO)) {
            NSString *str;
            CDTypeName *typeName;

            str = [lexer lexText];
            if ([str hasPrefix:@"<"] && [str hasSuffix:@">"]) {
                str = [str substringWithRange:NSMakeRange(1, [str length] - 2)];
                result = [[CDType alloc] initIDTypeWithProtocols:[str componentsSeparatedByString:@","]];
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
    } else if ([self isTokenInSimpleTypeSet:lookahead]) { // simple type
        int simpleType;

        simpleType = lookahead;
        [self match:simpleType];
        result = [[CDType alloc] initSimpleType:simpleType];
    } else {
        result = nil;
        [NSException raise:CDSyntaxError format:@"expected (many things), got %@", CDTokenDescription(lookahead)];
    }

    return [result autorelease];
}

// This seems to be used in method types -- no names
- (NSArray *)parseUnionTypes;
{
    NSMutableArray *members;

    members = [NSMutableArray array];

    while ([self isTokenInTypeSet:lookahead]) {
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

    //NSLog(@" > %s", _cmd);

    result = [NSMutableArray array];

    while (lookahead == TK_QUOTED_STRING || [self isTokenInTypeSet:lookahead])
        [result addObject:[self parseMember]];

    //NSLog(@"<  %s", _cmd);

    return result;
}

- (CDType *)parseMember;
{
    CDType *result;

    //NSLog(@" > %s", _cmd);

    if (lookahead == TK_QUOTED_STRING) {
        NSString *identifier = nil;

        while (lookahead == TK_QUOTED_STRING) {
            if (identifier == nil)
                identifier = [lexer lexText];
            else {
                // TextMate 1.5.4 has structures like... "storage""stack"{etc} -- two quoted strings next to each other.
                identifier = [NSString stringWithFormat:@"%@__%@", identifier, [lexer lexText]];
            }
            [self match:TK_QUOTED_STRING];
        }

        //NSLog(@"got identifier: %@", identifier);
        result = [self _parseTypeInStruct:YES];
        [result setVariableName:identifier];
        //NSLog(@"And parsed struct type.");
    } else {
        result = [self _parseTypeInStruct:YES];
    }

    //NSLog(@"<  %s", _cmd);
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
        [self match:'>' enterState:savedState];

        if ([lexer state] == CDTypeLexerStateTemplateTypes) {
            if (lookahead == TK_IDENTIFIER) {
                NSString *suffix = [lexer lexText];

                [self match:TK_IDENTIFIER];
                [typeName setSuffix:suffix];
            }
        }
    }

#if 0
    // This breaks a bunch of the unit tests... need to figure out what's up with that first.
    // We'll treat "?" as no name, returning nil here instead of testing the type name for this later.
    if ([[typeName name] isEqualToString:@"?"] && [typeName isTemplateType] == NO)
        typeName = nil;
#endif

    return typeName;
}

- (NSString *)parseIdentifier;
{
    NSString *result = nil;

    if (lookahead == TK_IDENTIFIER) {
        result = [lexer lexText];
        [self match:TK_IDENTIFIER];
    }

    return result;
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

- (BOOL)isTokenInModifierSet:(int)aToken;
{
    if (aToken == 'r'
        || aToken == 'n'
        || aToken == 'N'
        || aToken == 'o'
        || aToken == 'O'
        || aToken == 'R'
        || aToken == 'V')
        return YES;

    return NO;
}

- (BOOL)isTokenInSimpleTypeSet:(int)aToken;
{
    if (aToken == 'c'
        || aToken == 'i'
        || aToken == 's'
        || aToken == 'l'
        || aToken == 'q'
        || aToken == 'C'
        || aToken == 'I'
        || aToken == 'S'
        || aToken == 'L'
        || aToken == 'Q'
        || aToken == 'f'
        || aToken == 'd'
        || aToken == 'B'
        || aToken == 'v'
        || aToken == '*'
        || aToken == '#'
        || aToken == ':'
        || aToken == '%'
        || aToken == '?')
        return YES;

    return NO;
}

- (BOOL)isTokenInTypeSet:(int)aToken;
{
    if ([self isTokenInModifierSet:aToken]
        || [self isTokenInSimpleTypeSet:aToken]
        || aToken == '^'
        || aToken == 'b'
        || aToken == '@'
        || aToken == '{'
        || aToken == '('
        || aToken == '[')
        return YES;

    return NO;
}

- (BOOL)isTokenInTypeStartSet:(int)aToken;
{
    if (aToken == 'r'
        || aToken == 'n'
        || aToken == 'N'
        || aToken == 'o'
        || aToken == 'O'
        || aToken == 'R'
        || aToken == 'V'
        || aToken == '^'
        || aToken == 'b'
        || aToken == '@'
        || aToken == '{'
        || aToken == '('
        || aToken == '['
        || [self isTokenInSimpleTypeSet:aToken])
        return YES;

    return NO;
}

@end
