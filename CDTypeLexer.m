//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2007  Steve Nygard

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
    state = CDTypeLexerStateNormal;
    shouldShowLexing = NO;

    return self;
}

- (void)dealloc;
{
    [scanner release];
    [lexText release];

    [super dealloc];
}

- (NSScanner *)scanner;
{
    return scanner;
}

- (CDTypeLexerState)state;
{
    return state;
}

- (void)setState:(CDTypeLexerState)newState;
{
    state = newState;
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
            NSLog(@"%s [state=%d], token = TK_EOS", _cmd, state);
        return TK_EOS;
    }

    if (state == CDTypeLexerStateTemplateTypes) {
        // Skip whitespace, scan '<', ',', '>'.  Everything else is lumped together as a string.
        [scanner setCharactersToBeSkipped:[NSCharacterSet whitespaceCharacterSet]];
        if ([scanner scanString:@"<" intoString:NULL] == YES) {
            if (shouldShowLexing == YES)
                NSLog(@"%s [state=%d], token = %d '%c'", _cmd, state, '<', '<');
            return '<';
        }

        if ([scanner scanString:@">" intoString:NULL] == YES) {
            if (shouldShowLexing == YES)
                NSLog(@"%s [state=%d], token = %d '%c'", _cmd, state, '>', '>');
            return '>';
        }

        if ([scanner scanString:@"," intoString:NULL] == YES) {
            if (shouldShowLexing == YES)
                NSLog(@"%s [state=%d], token = %d '%c'", _cmd, state, ',', ',');
            return ',';
        }

        if ([scanner my_scanCharactersFromSet:[NSScanner cdTemplateTypeCharacterSet] intoString:&str] == YES) {
            [self _setLexText:str];
            if (shouldShowLexing == YES)
                NSLog(@"%s [state=%d], token = TK_TEMPLATE_TYPE (%@)", _cmd, state, lexText);
            return TK_TEMPLATE_TYPE;
        }

        NSLog(@"Ooops, fell through in template types state.");
    } else if (state == CDTypeLexerStateIdentifier) {
        NSString *anIdentifier;

        //NSLog(@"Scanning in identifier state.");
        [scanner setCharactersToBeSkipped:nil];

        if ([scanner scanIdentifierIntoString:&anIdentifier] == YES) {
            [self _setLexText:anIdentifier];
            if (shouldShowLexing == YES)
                NSLog(@"%s [state=%d], token = TK_IDENTIFIER (%@)", _cmd, state, lexText);
            state = CDTypeLexerStateNormal;
            return TK_IDENTIFIER;
        }
    } else {
        [scanner setCharactersToBeSkipped:nil];

        if ([scanner scanString:@"\"" intoString:NULL] == YES) {
            if ([scanner scanUpToString:@"\"" intoString:&str] == YES)
                [self _setLexText:str];
            else
                [self _setLexText:@""];
            [scanner scanString:@"\"" intoString:NULL];
            if (shouldShowLexing == YES)
                NSLog(@"%s [state=%d], token = TK_QUOTED_STRING (%@)", _cmd, state, lexText);
            return TK_QUOTED_STRING;
        }

        if ([scanner my_scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&str] == YES) {
            [self _setLexText:str];
            if (shouldShowLexing == YES)
                NSLog(@"%s [state=%d], token = TK_NUMBER (%@)", _cmd, state, lexText);
            return TK_NUMBER;
        }

        if ([scanner scanCharacter:&ch] == YES) {
            if (shouldShowLexing == YES)
                NSLog(@"%s [state=%d], token = %d '%c'", _cmd, state, ch, ch);
            return ch;
        }
    }

    if (shouldShowLexing == YES)
        NSLog(@"%s [state=%d], token = TK_EOS", _cmd, state);

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

@end
