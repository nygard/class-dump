//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2005  Steve Nygard

#import "CDTypeLexerUnitTest.h"

#import <Foundation/Foundation.h>
#import "CDTypeLexer.h"

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
    [self assertNotNil:lexer];

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

- (void)test1;
{
    [self showScannedTokensForString:@"^@"];
    [self showScannedTokensForString:@"\"field1\"@\"NSObject\"\"field2\"iic"];
    [self showScannedTokensForString:@"iiiiiii"];
}

- (void)test2;
{
    NSString *str = @"iiiiiiiiii)ii\"foo\"iii";

    [self _setupLexerForString:str];
    [lexer setState:CDTypeLexerStateIdentifier];
    [self _showScannedTokens];
    [self _cleanupLexer];
}

// This is testing a quoted string that isn't terminated...
- (void)test3;
{
    [self showScannedTokensForString:@"@\"NSObject"];
}

struct tokenValuePair {
    int token;
    NSString *value;
    int nextState;
};

- (void)test4;
{
    NSString *str = @"{vector<IPPhotoInfo*,std::allocator<IPPhotoInfo*> >=iic}";
    int token;
    struct tokenValuePair tokens[] = {
        { '{',              nil,               CDTypeLexerStateIdentifier },
        { TK_IDENTIFIER,    @"vector",         -1 },
        { '<',              nil,               CDTypeLexerStateTemplateTypes },
        { TK_TEMPLATE_TYPE, @"IPPhotoInfo*",   -1 },
        { ',',              nil,               -1 },
        { TK_TEMPLATE_TYPE, @"std::allocator", -1 },
        { '<',              nil,               CDTypeLexerStateTemplateTypes },
        { TK_TEMPLATE_TYPE, @"IPPhotoInfo*",   -1 },
        { '>',              nil,               -1 },
        { '>',              nil,               CDTypeLexerStateNormal },
        { '=',              nil,               -1 },
        { 'i',              nil,               -1 },
        { 'i',              nil,               -1 },
        { 'c',              nil,               -1 },
        { '}',              nil,               -1 },
        { TK_EOS,           nil,               -1 },
    };
    struct tokenValuePair *expectedResults = tokens;

    [self _setupLexerForString:str];
    NSLog(@"str: %@", [lexer string]);
    [lexer setShouldShowLexing:YES];

    while (expectedResults->token != TK_EOS) {
        token = [lexer scanNextToken];
        [self assertInt:token equals:expectedResults->token];
        if (expectedResults->value != nil)
            [self assert:[lexer lexText] equals:expectedResults->value];
        if (expectedResults->nextState != -1)
            [lexer setState:expectedResults->nextState];
        expectedResults++;
    }

    [self assertInt:[lexer scanNextToken] equals:TK_EOS];

    [self _cleanupLexer];
}

@end
