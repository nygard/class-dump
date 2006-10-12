//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2005  Steve Nygard

#import <ObjcUnit/TestCase.h>

@class CDTypeLexer;

@interface CDTypeLexerUnitTest : TestCase
{
    CDTypeLexer *lexer;
}

- (void)setUp;
- (void)tearDown;

- (void)_setupLexerForString:(NSString *)str;
- (void)_cleanupLexer;

- (void)_showScannedTokens;
- (void)showScannedTokensForString:(NSString *)str;
- (void)test1;

@end
