//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2005  Steve Nygard

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h> // for unichar

#define TK_EOS 0
#define TK_NUMBER 257
#define TK_IDENTIFIER 258
#define T_NAMED_OBJECT 259
#define TK_QUOTED_STRING 260
#define TK_TEMPLATE_TYPE TK_IDENTIFIER

typedef enum {
    CDTypeLexerStateNormal = 0,
    CDTypeLexerStateIdentifier = 1,
    CDTypeLexerStateTemplateTypes = 2,
} CDTypeLexerState;

@class NSCharacterSet, NSScanner;

@interface CDTypeLexer : NSObject
{
    NSScanner *scanner;
    CDTypeLexerState state;
    NSString *lexText;

    BOOL shouldShowLexing;
}

- (id)initWithString:(NSString *)aString;
- (void)dealloc;

- (NSScanner *)scanner;

- (CDTypeLexerState)state;
- (void)setState:(CDTypeLexerState)newState;

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
