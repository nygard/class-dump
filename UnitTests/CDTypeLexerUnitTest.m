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
    [self showScannedTokensForString:@"@\"NSObject\"\"field1\"iic"];
    [self showScannedTokensForString:@"iiiiiii"];
}

- (void)test2;
{
    NSString *str = @"iiiiiiiiii)ii\"foo\"iii";

    [self _setupLexerForString:str];
    [lexer setIsInIdentifierState:YES];
    [self _showScannedTokens];
    [self _cleanupLexer];
}

// This is testing a quoted string that isn't terminated...
- (void)test3;
{
    [self showScannedTokensForString:@"@\"NSObject"];
}

@end
