// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#define TK_EOS                  0
#define TK_NUMBER               257
#define TK_IDENTIFIER           258
#define T_NAMED_OBJECT          259
#define TK_QUOTED_STRING        260
#define TK_TEMPLATE_TYPE        TK_IDENTIFIER
#define T_FUNCTION_POINTER_TYPE 1001
#define T_BLOCK_TYPE            1002

typedef enum : NSUInteger {
    CDTypeLexerState_Normal        = 0,
    CDTypeLexerState_Identifier    = 1,
    CDTypeLexerState_TemplateTypes = 2,
} CDTypeLexerState;

@interface CDTypeLexer : NSObject

- (id)initWithString:(NSString *)string;

@property (readonly) NSScanner *scanner;
@property (nonatomic, assign) CDTypeLexerState state;
@property (assign) BOOL shouldShowLexing;

@property (nonatomic, readonly) NSString *string;
- (int)scanNextToken;

@property (strong) NSString *lexText;

@property (nonatomic, readonly) unichar peekChar;
@property (nonatomic, readonly) NSString *remainingString;
@property (nonatomic, readonly) NSString *peekIdentifier;

@end
