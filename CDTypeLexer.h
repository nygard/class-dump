//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h> // for unichar

#define TK_EOS 0
#define TK_NUMBER 257
#define TK_IDENTIFIER 258
#define T_NAMED_OBJECT 259

@class NSCharacterSet, NSScanner;

@interface CDTypeLexer : NSObject
{
    NSScanner *scanner;
    BOOL isInIdentifierState;
    NSString *lexText;

    BOOL shouldShowLexing;
}

- (id)initWithString:(NSString *)aString;
- (void)dealloc;

- (BOOL)isInIdentifierState;
- (void)setIsInIdentifierState:(BOOL)newFlag;

- (BOOL)shouldShowLexing;
- (void)setShouldShowLexing:(BOOL)newFlag;

- (NSString *)string;
- (int)scanNextToken;

- (NSString *)lexText;
- (void)_setLexText:(NSString *)newString;

- (unichar)peekChar;
- (NSString *)remainingString;
- (NSString *)peekIdentifier;

@end
