//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2005  Steve Nygard

#import "CDTypeLexer.h"

#import <Foundation/Foundation.h>
#import "NSScanner-Extensions.h"

@implementation CDTypeLexer

- (id)initWithString:(NSString *)aString;
{
    if ([super init] == nil)
        return nil;

    scanner = [[NSScanner alloc] initWithString:aString];
    [scanner setCharactersToBeSkipped:nil];
    isInIdentifierState = NO;
    shouldShowLexing = NO;

    return self;
}

- (void)dealloc;
{
    [scanner release];
    [lexText release];

    [super dealloc];
}

- (BOOL)isInIdentifierState;
{
    return isInIdentifierState;
}

- (void)setIsInIdentifierState:(BOOL)newFlag;
{
    isInIdentifierState = newFlag;
}

- (BOOL)shouldShowLexing;
{
    return shouldShowLexing;
}

- (void)setShouldShowLexing:(BOOL)newFlag;
{
    shouldShowLexing = newFlag;
}

- (NSString *)string;
{
    return [scanner string];
}

- (int)scanNextToken;
{
    NSString *str;
    unichar ch;

    [self _setLexText:nil];

    if ([scanner isAtEnd] == YES) {
        if (shouldShowLexing == YES)
            NSLog(@"%s [id=%d], token = TK_EOS", _cmd, isInIdentifierState);
        return TK_EOS;
    }

    if ([scanner scanString:@"\"" intoString:NULL] == YES) {
        [scanner scanUpToString:@"\"" intoString:&str];
        [self _setLexText:str];
        [scanner scanString:@"\"" intoString:NULL];
        if (shouldShowLexing == YES)
            NSLog(@"%s [id=%d], token = TK_QUOTED_STRING (%@)", _cmd, isInIdentifierState, lexText);
        return TK_QUOTED_STRING;
    }

    if (isInIdentifierState == YES) {
        NSString *anIdentifier;

        //NSLog(@"Scanning in identifier state.");

        if ([scanner scanIdentifierIntoString:&anIdentifier] == YES) {
            [self _setLexText:anIdentifier];
            [self setIsInIdentifierState:NO];
            if (shouldShowLexing == YES)
                NSLog(@"%s [id=%d], token = TK_IDENTIFIER (%@)", _cmd, isInIdentifierState, lexText);
            return TK_IDENTIFIER;
        }
    }

    if ([scanner my_scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&str] == YES) {
        [self _setLexText:str];
        if (shouldShowLexing == YES)
            NSLog(@"%s [id=%d], token = TK_NUMBER (%@)", _cmd, isInIdentifierState, lexText);
        return TK_NUMBER;
    }

    if ([scanner scanCharacter:&ch] == YES) {
        if (shouldShowLexing == YES)
            NSLog(@"%s [id=%d], token = %d '%c'", _cmd, isInIdentifierState, ch, ch);
        return ch;
    }

    if (shouldShowLexing == YES)
        NSLog(@"%s [id=%d], token = TK_EOS", _cmd, isInIdentifierState);

    return TK_EOS;
}

- (NSString *)lexText;
{
    return lexText;
}

- (void)_setLexText:(NSString *)newString;
{
    if (newString == lexText)
        return;

    [lexText release];
    lexText = [newString retain];
}

- (unichar)peekChar;
{
    return [scanner peekChar];
}

- (NSString *)remainingString;
{
    return [[scanner string] substringFromIndex:[scanner scanLocation]];
}

- (NSString *)peekIdentifier;
{
    NSScanner *aScanner;
    NSString *anIdentifier;

    aScanner = [[NSScanner alloc] initWithString:[scanner string]];
    [aScanner setScanLocation:[scanner scanLocation]];

    if ([aScanner scanIdentifierIntoString:&anIdentifier] == YES) {
        [aScanner release];
        return anIdentifier;
    }

    [aScanner release];

    return nil;
}

- (NSScanner *)scanner;
{
    return scanner;
}

@end
