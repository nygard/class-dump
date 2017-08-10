//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDTypeLexerUnitTest.h"

#import <Foundation/Foundation.h>
#import "CDTypeLexer.h"

struct tokenValuePair {
    int token;
    NSString *value;
    int nextState;
};

@implementation CDTypeLexerUnitTest

- (void)setUp;
{
}

- (void)tearDown;
{
}

- (void)_setupLexerForString:(NSString *)str;
{
    lexer = [[CDTypeLexer alloc] initWithString:str];
}

- (void)_cleanupLexer;
{
    [lexer release];
    lexer = nil;
}

- (void)_showScannedTokens;
{
    int token;

    NSLog(@"----------------------------------------");
    STAssertNotNil(lexer, @"");

    NSLog(@"str: %@", [lexer string]);

    [lexer setShouldShowLexing:YES];

    token = [lexer scanNextToken];
    while (token != TK_EOS)
        token = [lexer scanNextToken];
    NSLog(@"----------------------------------------");
}

- (void)showScannedTokensForString:(NSString *)str;
{
    [self _setupLexerForString:str];
    [self _showScannedTokens];
    [self _cleanupLexer];
}

// The last token in expectedResults must be TK_EOS.
- (void)testLexingString:(NSString *)str expectedResults:(struct tokenValuePair *)expectedResults;
{
    int token;

    [self _setupLexerForString:str];
    //NSLog(@"str: %@", [lexer string]);
    //[lexer setShouldShowLexing:YES];

    while (expectedResults->token != TK_EOS) {
        token = [lexer scanNextToken];
        STAssertEquals(expectedResults->token, token, @"");
        if (expectedResults->value != nil)
            STAssertEqualObjects(expectedResults->value, [lexer lexText], @"");
        if (expectedResults->nextState != -1)
            [lexer setState:expectedResults->nextState];
        expectedResults++;
    }

    token = [lexer scanNextToken];
    STAssertEquals(TK_EOS, token, @"");

    [self _cleanupLexer];
}

- (void)testSimpleTokens;
{
    NSString *str = @"i^@";
    struct tokenValuePair tokens[] = {
        { 'i',              nil,               -1 },
        { '^',              nil,               -1 },
        { '@',              nil,               -1 },
        { TK_EOS,           nil,               -1 },
    };

    [self testLexingString:str expectedResults:tokens];
}

- (void)testQuotedStringToken;
{
    NSString *str = @"@\"NSObject\"";
    struct tokenValuePair tokens[] = {
        { '@',              nil,               -1 },
        { TK_QUOTED_STRING, @"NSObject",       -1 },
        { TK_EOS,           nil,               -1 },
    };

    [self testLexingString:str expectedResults:tokens];
}

- (void)testEmptyQuotedStringToken;
{
    NSString *str = @"@\"\"";
    struct tokenValuePair tokens[] = {
        { '@',              nil,               -1 },
        { TK_QUOTED_STRING, @"",               -1 },
        { TK_EOS,           nil,               -1 },
    };

    [self testLexingString:str expectedResults:tokens];
}

- (void)testUnterminatedQuotedString;
{
    NSString *str = @"@\"NSObject";
    struct tokenValuePair tokens[] = {
        { '@',              nil,               -1 },
        { TK_QUOTED_STRING, @"NSObject",       -1 },
        { TK_EOS,           nil,               -1 },
    };

    [self testLexingString:str expectedResults:tokens];
}

// The lexer should automatically switch back to normal mode after scanning one identifier.
- (void)testIdentifierToken;
{
    NSString *str = @"iii)ii";
    struct tokenValuePair tokens[] = {
        { 'i',              nil,               CDTypeLexerState_Identifier },
        { TK_IDENTIFIER,    @"ii",             -1 },
        { ')',              nil,               -1 },
        { 'i',              nil,               -1 },
        { 'i',              nil,               -1 },
        { TK_EOS,           nil,               -1 },
    };

    [self testLexingString:str expectedResults:tokens];
}


// This tests a more complicated C++ template type, and makes sure the space between the '>'s is ignored.
- (void)testTemplateTokens;
{
    NSString *str = @"{vector<IPPhotoInfo*,std::allocator<IPPhotoInfo*> >=iic}";
    struct tokenValuePair tokens[] = {
        { '{',              nil,               CDTypeLexerState_Identifier },
        { TK_IDENTIFIER,    @"vector",         -1 },
        { '<',              nil,               CDTypeLexerState_TemplateTypes },
        { TK_TEMPLATE_TYPE, @"IPPhotoInfo*",   -1 },
        { ',',              nil,               -1 },
        { TK_TEMPLATE_TYPE, @"std::allocator", -1 },
        { '<',              nil,               CDTypeLexerState_TemplateTypes },
        { TK_TEMPLATE_TYPE, @"IPPhotoInfo*",   -1 },
        { '>',              nil,               -1 },
        { '>',              nil,               CDTypeLexerState_Normal },
        { '=',              nil,               -1 },
        { 'i',              nil,               -1 },
        { 'i',              nil,               -1 },
        { 'c',              nil,               -1 },
        { '}',              nil,               -1 },
        { TK_EOS,           nil,               -1 },
    };

    [self testLexingString:str expectedResults:tokens];
}

@end
