// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import <SenTestingKit/SenTestingKit.h>

@class CDTypeLexer;

@interface CDTypeLexerUnitTest : SenTestCase
{
    CDTypeLexer *lexer;
}

- (void)setUp;
- (void)tearDown;

- (void)_setupLexerForString:(NSString *)str;
- (void)_cleanupLexer;
- (void)_showScannedTokens;
- (void)showScannedTokensForString:(NSString *)str;

- (void)testLexingString:(NSString *)str expectedResults:(struct tokenValuePair *)expectedResults;

- (void)testSimpleTokens;
- (void)testQuotedStringToken;
- (void)testEmptyQuotedStringToken;
- (void)testUnterminatedQuotedString;
- (void)testIdentifierToken;
- (void)testTemplateTokens;

@end
