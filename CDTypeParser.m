//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import "CDTypeParser.h"

#import "rcsid.h"
#include <assert.h>
#import <Foundation/Foundation.h>
#import "CDMethodType.h"
#import "CDType.h"
#import "CDTypeName.h"
#import "CDTypeLexer.h"
#import "NSString-Extensions.h"

RCS_ID("$Header: /Volumes/Data/tmp/Tools/class-dump/CDTypeParser.m,v 1.26 2004/01/20 05:01:54 nygard Exp $");

//----------------------------------------------------------------------

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
        lookahead = [lexer nextToken];
        result = [self _parseMethodType];
    } NS_HANDLER {
        NSLog(@"caught exception: %@", localException);
        NSLog(@"type: %@", [lexer string]);

        // TODO (2003-12-19): Free stuff if necessary
        result = nil;
    } NS_ENDHANDLER;

    return result;
}

- (CDType *)parseType;
{
    CDType *result;

    NS_DURING {
        lookahead = [lexer nextToken];
        result = [self _parseType];
    } NS_HANDLER {
        NSLog(@"caught exception: %@", localException);
        NSLog(@"type: %@", [lexer string]);

        // TODO (2003-12-19): Free stuff if necessary
        result = nil;
    } NS_ENDHANDLER;

    return result;
}

@end

@implementation CDTypeParser (Private)

- (void)match:(int)token;
{
    [self match:token allowIdentifier:NO];
}

- (void)match:(int)token allowIdentifier:(BOOL)shouldAllowIdentifier;
{
    if (lookahead == token) {
        //NSLog(@"matched %@", CDTokenDescription(token));
        if (shouldAllowIdentifier == YES)
            [lexer setIsInIdentifierState:YES];
        lookahead = [lexer nextToken];
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

- (CDType *)_parseType;
{
    return [self _parseTypeUseClassNameHeuristics:NO];
}

- (CDType *)_parseTypeUseClassNameHeuristics:(BOOL)shouldUseHeuristics;
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
            unmodifiedType = [self _parseTypeUseClassNameHeuristics:shouldUseHeuristics];
        else
            unmodifiedType = nil;
        result = [[CDType alloc] initModifier:modifier type:unmodifiedType];
    } else if (lookahead == '^') { // pointer
        CDType *type;

        [self match:'^'];
        type = [self _parseTypeUseClassNameHeuristics:shouldUseHeuristics];
        result = [[CDType alloc] initPointerType:type];
    } else if (lookahead == 'b') { // bitfield
        NSString *number;

        [self match:'b'];
        number = [self parseNumber];
        result = [[CDType alloc] initBitfieldType:number];
    } else if (lookahead == '@') { // id
        [self match:'@'];

        if (lookahead == '"' && (shouldUseHeuristics == NO
                                        || [[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:[lexer peekChar]] == YES)) {
            NSString *name;
            CDTypeName *typeName;

            name = [self parseQuotedName];
            typeName = [[CDTypeName alloc] init];
            [typeName setName:name];
            result = [[CDType alloc] initIDType:typeName];
            [typeName release];
        } else {
            result = [[CDType alloc] initIDType:nil];
        }
    } else if (lookahead == '{') { // structure
        CDTypeName *typeName;
        NSArray *optionalMembers;

        [self match:'{' allowIdentifier:YES];
        typeName = [self parseTypeName];
        optionalMembers = [self parseOptionalMembers];
        [self match:'}'];

        result = [[CDType alloc] initStructType:typeName members:optionalMembers];
    } else if (lookahead == '(') { // union
        [self match:'(' allowIdentifier:YES];
        if (lookahead == TK_IDENTIFIER) {
            CDTypeName *typeName;
            NSArray *optionalMembers;

            typeName = [self parseTypeName]; // 2004-01-17: This is new, used to just be parseIdentifier
            optionalMembers = [self parseOptionalMembers];
            [self match:')'];

            result = [[CDType alloc] initUnionType:typeName members:optionalMembers];
        } else {
            NSArray *unionTypes;

            unionTypes = [self parseUnionTypes];
            [self match:')'];

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
        result = NULL;
        [NSException raise:CDSyntaxError format:@"expected (many things), got %d", lookahead];
    }

    return result;
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
    while (lookahead == '"' || [self isLookaheadInTypeSet] == YES) {
        [result addObject:[self parseMember]];
    }

    return result;
}

- (CDType *)parseMember;
{
    CDType *result;

    if (lookahead == '"') {
        NSString *identifier;

        identifier = [self parseQuotedName];
        result = [self _parseTypeUseClassNameHeuristics:YES];
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
        //NSLog(@"Matching template class...");
        [self match:'<' allowIdentifier:YES];
        [typeName addTemplateType:[self parseTypeName]];
        while (lookahead == ',') {
            [self match:',' allowIdentifier:YES];
            [typeName addTemplateType:[self parseTypeName]];
        }
        [self match:'>' allowIdentifier:NO];
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

- (NSString *)parseQuotedName;
{
    [self match:'"' allowIdentifier:YES];
    if (lookahead == '"') {
        [self match:'"'];
        return @"";
    } else {
        NSString *identifier;

        identifier = [self parseIdentifier];
        [self match:'"'];
        return identifier;
    }
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
