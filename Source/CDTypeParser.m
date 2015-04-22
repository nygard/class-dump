// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDTypeParser.h"

#import "CDMethodType.h"
#import "CDType.h"
#import "CDTypeName.h"
#import "CDTypeLexer.h"

NSString *CDExceptionName_SyntaxError         = @"CDExceptionName_SyntaxError";

NSString *CDErrorDomain_TypeParser            = @"CDErrorDomain_TypeParser";

NSString *CDErrorKey_Type                     = @"CDErrorKey_Type";
NSString *CDErrorKey_RemainingString          = @"CDErrorKey_RemainingString";
NSString *CDErrorKey_MethodOrVariable         = @"CDErrorKey_MethodOrVariable";
NSString *CDErrorKey_LocalizedLongDescription = @"CDErrorKey_LocalizedLongDescription";

static BOOL debug = NO;

static NSString *CDTokenDescription(int token)
{
    if (token < 128)
        return [NSString stringWithFormat:@"%d(%c)", token, token];

    return [NSString stringWithFormat:@"%d", token];
}

@interface CDTypeParser ()
@end

#pragma mark -

@implementation CDTypeParser
{
    CDTypeLexer *_lexer;
    int _lookahead;
}

- (id)initWithString:(NSString *)string;
{
    if ((self = [super init])) {
        // Do some preprocessing first: Replace "<unnamed>::" with just "unnamed::".
        NSMutableString *str = [string mutableCopy];
        [str replaceOccurrencesOfString:@"<unnamed>::" withString:@"unnamed::" options:(NSStringCompareOptions)0 range:NSMakeRange(0, [string length])];
        
        _lexer = [[CDTypeLexer alloc] initWithString:str];
        _lookahead = 0;
    }

    return self;
}

#pragma mark -

- (NSArray *)parseMethodType:(NSError *__autoreleasing *)error;
{
    NSArray *result;

    @try {
        _lookahead = [self.lexer scanNextToken];
        result = [self _parseMethodType];
    }
    @catch (NSException *exception) {
        if (error != NULL) {
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            NSString *localDesc = [NSString stringWithFormat:@"%@:\n\t     type: %@\n\tremaining: %@", [exception reason], self.lexer.string, self.lexer.remainingString];            

            userInfo[CDErrorKey_Type]                     = self.lexer.string;
            userInfo[CDErrorKey_RemainingString]          = self.lexer.remainingString;
            userInfo[CDErrorKey_MethodOrVariable]         = @"method";
            userInfo[CDErrorKey_LocalizedLongDescription] = localDesc;
            
            NSInteger code;
            if ([exception name] == CDExceptionName_SyntaxError) {
                code = CDTypeParserCode_SyntaxError;
                userInfo[NSLocalizedDescriptionKey]        = @"Syntax Error";
                userInfo[NSLocalizedFailureReasonErrorKey] = [exception reason];
            } else {
                code = CDTypeParserCode_Default;
                userInfo[NSLocalizedFailureReasonErrorKey] = [exception reason];
            }
            *error = [NSError errorWithDomain:CDErrorDomain_TypeParser code:code userInfo:userInfo];
        }

        result = nil;
    }

    return result;
}

- (CDType *)parseType:(NSError *__autoreleasing *)error;
{
    CDType *result;

    @try {
        _lookahead = [self.lexer scanNextToken];
        result = [self _parseType];
    }
    @catch (NSException *exception) {
        if (error != NULL) {
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            NSString *localDesc = [NSString stringWithFormat:@"%@:\n\t     type: %@\n\tremaining: %@", [exception reason], self.lexer.string, self.lexer.remainingString];
            
            userInfo[CDErrorKey_Type]                     = self.lexer.string;
            userInfo[CDErrorKey_RemainingString]          = self.lexer.remainingString;
            userInfo[CDErrorKey_MethodOrVariable]         = @"variable";
            userInfo[CDErrorKey_LocalizedLongDescription] = localDesc;
            
            NSInteger code;
            if ([exception name] == CDExceptionName_SyntaxError) {
                code = CDTypeParserCode_SyntaxError;
                userInfo[NSLocalizedDescriptionKey]        = @"Syntax Error";
                userInfo[NSLocalizedFailureReasonErrorKey] = [exception reason];
            } else {
                code = CDTypeParserCode_Default;
                userInfo[NSLocalizedFailureReasonErrorKey] = [exception reason];
            }
            *error = [NSError errorWithDomain:CDErrorDomain_TypeParser code:code userInfo:userInfo];
        }

        result = nil;
    }

    return result;
}

#pragma mark - Private methods

- (void)match:(int)token;
{
    [self match:token enterState:self.lexer.state];
}

- (void)match:(int)token enterState:(CDTypeLexerState)newState;
{
    if (_lookahead == token) {
        if (debug) NSLog(@"matched %@", CDTokenDescription(token));
        self.lexer.state = newState;
        _lookahead = [self.lexer scanNextToken];
    } else {
        [NSException raise:CDExceptionName_SyntaxError format:@"expected token %@, got %@",
                     CDTokenDescription(token),
                     CDTokenDescription(_lookahead)];
    }
}

- (void)error:(NSString *)errorString;
{
    [NSException raise:CDExceptionName_SyntaxError format:@"%@", errorString];
}

- (NSArray *)_parseMethodType;
{
    NSMutableArray *methodTypes = [NSMutableArray array];

    // Has to have at least one pair for the return type;
    // Probably needs at least two more, for object and selector
    // So it must be <type><number><type><number><type><number>.  Three pairs at a minimum.

    do {
        CDType *type = [self _parseType];
        NSString *number = [self parseNumber];

        CDMethodType *methodType = [[CDMethodType alloc] initWithType:type offset:number];
        [methodTypes addObject:methodType];
    } while ([self isTokenInTypeStartSet:_lookahead]);

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

    if (_lookahead == 'j'
        || _lookahead == 'r'
        || _lookahead == 'n'
        || _lookahead == 'N'
        || _lookahead == 'o'
        || _lookahead == 'O'
        || _lookahead == 'R'
        || _lookahead == 'V') { // modifiers
        int modifier = _lookahead;
        [self match:modifier];

        CDType *unmodifiedType;
        if ([self isTokenInTypeStartSet:_lookahead])
            unmodifiedType = [self _parseTypeInStruct:isInStruct];
        else
            unmodifiedType = nil;
        result = [[CDType alloc] initModifier:modifier type:unmodifiedType];
    } else if (_lookahead == '^') { // pointer
        CDType *type;

        [self match:'^'];
        if (_lookahead == TK_QUOTED_STRING || _lookahead == '}' || _lookahead == ')') {
            type = [[CDType alloc] initSimpleType:'v'];
            // Safari on 10.5 has: "m_function"{?="__pfn"^"__delta"i}
            result = [[CDType alloc] initPointerType:type];
        } else if (_lookahead == '?') {
            [self match:'?'];
            result = [[CDType alloc] initFunctionPointerType];
        } else {
            type = [self _parseTypeInStruct:isInStruct];
            result = [[CDType alloc] initPointerType:type];
        }
    } else if (_lookahead == 'b') { // bitfield
        [self match:'b'];
        NSString *number = [self parseNumber];
        result = [[CDType alloc] initBitfieldType:number];
    } else if (_lookahead == '@') { // id
        [self match:'@'];
#if 0
        if (lookahead == TK_QUOTED_STRING) {
            NSLog(@"%s, quoted string ahead, shouldCheckFieldNames: %d, end: %d",
                  __cmd, shouldCheckFieldNames, [lexer.scanner isAtEnd]);
            if ([lexer.scanner isAtEnd] == NO)
                NSLog(@"next character: %d (%c), isInTypeStartSet: %d", lexer.peekChar, lexer.peekChar, [self isTokenInTypeStartSet:lexer.peekChar]);
        }
#endif
        if (_lookahead == TK_QUOTED_STRING && (isInStruct == NO || [self.lexer.lexText isFirstLetterUppercase] || [self isTokenInTypeStartSet:self.lexer.peekChar] == NO)) {
            NSString *str = self.lexer.lexText;
            
            NSUInteger protocolOpenIdx = NSMaxRange([str rangeOfString:@"<"]);
            NSUInteger protocolCloseIdx = [str rangeOfString:@">" options:NSBackwardsSearch].location;
            if (protocolOpenIdx != NSNotFound && protocolCloseIdx != NSNotFound) {
                NSRange protocolRange = NSMakeRange(protocolOpenIdx, protocolCloseIdx - protocolOpenIdx);
                NSArray *protocols = [[str substringWithRange:protocolRange] componentsSeparatedByString:@","];
                
                NSString *typeNameStr = [[str substringToIndex:(protocolOpenIdx - 1)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                CDTypeName *typeName = nil;
                if ([typeNameStr length] && ![typeNameStr isEqualToString:@"id"]) {
                    typeName = [[CDTypeName alloc] init];
                    typeName.name = typeNameStr;
                }
                
                result = [[CDType alloc] initIDType:typeName withProtocols:protocols];
            } else {
                CDTypeName *typeName = [[CDTypeName alloc] init];
                typeName.name = str;
                result = [[CDType alloc] initIDType:typeName];
            }

            [self match:TK_QUOTED_STRING];
        } else if (_lookahead == '?') {
            [self match:'?'];
            NSArray *blockTypes = nil;
            if (_lookahead == '<') {
                [self match:'<'];
                blockTypes = [[self _parseMethodType] valueForKeyPath:@"type"];
                [self match:'>'];
            }
            result = [[CDType alloc] initBlockTypeWithTypes:blockTypes];
        } else {
            result = [[CDType alloc] initIDType:nil];
        }
    } else if (_lookahead == '{') { // structure
        CDTypeLexerState savedState = self.lexer.state;
        [self match:'{' enterState:CDTypeLexerState_Identifier];
        CDTypeName *typeName = [self parseTypeName];
        NSArray *optionalMembers = [self parseOptionalMembers];
        [self match:'}' enterState:savedState];

        result = [[CDType alloc] initStructType:typeName members:optionalMembers];
    } else if (_lookahead == '(') { // union
        CDTypeLexerState savedState = self.lexer.state;
        [self match:'(' enterState:CDTypeLexerState_Identifier];
        if (_lookahead == TK_IDENTIFIER) {
            CDTypeName *typeName = [self parseTypeName];
            NSArray *optionalMembers = [self parseOptionalMembers];
            [self match:')' enterState:savedState];

            result = [[CDType alloc] initUnionType:typeName members:optionalMembers];
        } else {
            NSArray *unionTypes = [self parseUnionTypes];
            [self match:')' enterState:savedState];

            result = [[CDType alloc] initUnionType:nil members:unionTypes];
        }
    } else if (_lookahead == '[') { // array
        [self match:'['];
        NSString *number = [self parseNumber];
        CDType *type = [self _parseType];
        [self match:']'];

        result = [[CDType alloc] initArrayType:type count:number];
    } else if ([self isTokenInSimpleTypeSet:_lookahead]) { // simple type
        int simpleType = _lookahead;
        [self match:simpleType];
        result = [[CDType alloc] initSimpleType:simpleType];
    } else {
        result = nil;
        [NSException raise:CDExceptionName_SyntaxError format:@"expected (many things), got %@", CDTokenDescription(_lookahead)];
    }

    return result;
}

// This seems to be used in method types -- no names
- (NSArray *)parseUnionTypes;
{
    NSMutableArray *members = [NSMutableArray array];

    while ([self isTokenInTypeSet:_lookahead]) {
        CDType *type = [self _parseType];
        //type.variableName = @"___";
        [members addObject:type];
    }

    return members;
}

- (NSArray *)parseOptionalMembers;
{
    NSArray *result;

    if (_lookahead == '=') {
        [self match:'='];
        result = [self parseMemberList];
    } else
        result = nil;

    return result;
}

- (NSArray *)parseMemberList;
{
    //NSLog(@" > %s", __cmd);

    NSMutableArray *result = [NSMutableArray array];

    while (_lookahead == TK_QUOTED_STRING || [self isTokenInTypeSet:_lookahead])
        [result addObject:[self parseMember]];

    //NSLog(@"<  %s", __cmd);

    return result;
}

- (CDType *)parseMember;
{
    CDType *result;

    //NSLog(@" > %s", __cmd);

    if (_lookahead == TK_QUOTED_STRING) {
        NSString *identifier = nil;

        while (_lookahead == TK_QUOTED_STRING) {
            if (identifier == nil)
                identifier = self.lexer.lexText;
            else {
                // TextMate 1.5.4 has structures like... "storage""stack"{etc} -- two quoted strings next to each other.
                identifier = [NSString stringWithFormat:@"%@__%@", identifier, self.lexer.lexText];
            }
            [self match:TK_QUOTED_STRING];
        }

        //NSLog(@"got identifier: %@", identifier);
        result = [self _parseTypeInStruct:YES];
        result.variableName = identifier;
        //NSLog(@"And parsed struct type.");
    } else {
        result = [self _parseTypeInStruct:YES];
    }

    //NSLog(@"<  %s", __cmd);
    return result;
}

- (CDTypeName *)parseTypeName;
{
    CDTypeName *typeName = [[CDTypeName alloc] init];
    [typeName setName:[self parseIdentifier]];

    if (_lookahead == '<') {
        CDTypeLexerState savedState = self.lexer.state;
        [self match:'<' enterState:CDTypeLexerState_TemplateTypes];
        [typeName.templateTypes addObject:[self parseTypeName]];
        while (_lookahead == ',') {
            [self match:','];
            [typeName.templateTypes addObject:[self parseTypeName]];
        }
        [self match:'>' enterState:savedState];

        if (self.lexer.state == CDTypeLexerState_TemplateTypes) {
            if (_lookahead == TK_IDENTIFIER) {
                NSString *suffix = self.lexer.lexText;

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

    if (_lookahead == TK_IDENTIFIER) {
        result = self.lexer.lexText;
        [self match:TK_IDENTIFIER];
    }

    return result;
}

- (NSString *)parseNumber;
{
    if (_lookahead == TK_NUMBER) {
        NSString *result = self.lexer.lexText;
        [self match:TK_NUMBER];
        return result;
    }

    return nil;
}

- (BOOL)isTokenInModifierSet:(int)token;
{
    if (token == 'j'
        || token == 'r'
        || token == 'n'
        || token == 'N'
        || token == 'o'
        || token == 'O'
        || token == 'R'
        || token == 'V')
        return YES;

    return NO;
}

- (BOOL)isTokenInSimpleTypeSet:(int)token;
{
    if (token == 'c'
        || token == 'i'
        || token == 's'
        || token == 'l'
        || token == 'q'
        || token == 'C'
        || token == 'I'
        || token == 'S'
        || token == 'L'
        || token == 'Q'
        || token == 'f'
        || token == 'd'
        || token == 'D'
        || token == 'B'
        || token == 'v'
        || token == '*'
        || token == '#'
        || token == ':'
        || token == '%'
        || token == '?')
        return YES;

    return NO;
}

- (BOOL)isTokenInTypeSet:(int)token;
{
    if ([self isTokenInModifierSet:token]
        || [self isTokenInSimpleTypeSet:token]
        || token == '^'
        || token == 'b'
        || token == '@'
        || token == '{'
        || token == '('
        || token == '[')
        return YES;

    return NO;
}

- (BOOL)isTokenInTypeStartSet:(int)token;
{
    if (token == 'r'
        || token == 'n'
        || token == 'N'
        || token == 'o'
        || token == 'O'
        || token == 'R'
        || token == 'V'
        || token == '^'
        || token == 'b'
        || token == '@'
        || token == '{'
        || token == '('
        || token == '['
        || [self isTokenInSimpleTypeSet:token])
        return YES;

    return NO;
}

@end
