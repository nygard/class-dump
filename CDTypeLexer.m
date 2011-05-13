// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2011 Steve Nygard.

#import "CDTypeLexer.h"

#import "NSScanner-Extensions.h"

static BOOL debug = NO;

static NSString *CDTypeLexerStateName(CDTypeLexerState state)
{
    switch (state) {
      case CDTypeLexerState_Normal: return @"Normal";
      case CDTypeLexerState_Identifier: return @"Identifier";
      case CDTypeLexerState_TemplateTypes: return @"Template";
    }

    return @"Unknown";
}

@implementation CDTypeLexer

- (id)initWithString:(NSString *)aString;
{
    if ([super init] == nil)
        return nil;

    scanner = [[NSScanner alloc] initWithString:aString];
    [scanner setCharactersToBeSkipped:nil];
    state = CDTypeLexerState_Normal;
    shouldShowLexing = debug;

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
    if (debug) NSLog(@"CDTypeLexer - changing state from %lu (%@) to %lu (%@)", state, CDTypeLexerStateName(state), newState, CDTypeLexerStateName(newState));
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

    if ([scanner isAtEnd]) {
        if (shouldShowLexing)
            NSLog(@"%s [state=%lu], token = TK_EOS", __cmd, state);
        return TK_EOS;
    }

    if (state == CDTypeLexerState_TemplateTypes) {
        // Skip whitespace, scan '<', ',', '>'.  Everything else is lumped together as a string.
        [scanner setCharactersToBeSkipped:[NSCharacterSet whitespaceCharacterSet]];
        if ([scanner scanString:@"<" intoString:NULL]) {
            if (shouldShowLexing)
                NSLog(@"%s [state=%lu], token = %d '%c'", __cmd, state, '<', '<');
            return '<';
        }

        if ([scanner scanString:@">" intoString:NULL]) {
            if (shouldShowLexing)
                NSLog(@"%s [state=%lu], token = %d '%c'", __cmd, state, '>', '>');
            return '>';
        }

        if ([scanner scanString:@"," intoString:NULL]) {
            if (shouldShowLexing)
                NSLog(@"%s [state=%lu], token = %d '%c'", __cmd, state, ',', ',');
            return ',';
        }

        if ([scanner my_scanCharactersFromSet:[NSScanner cdTemplateTypeCharacterSet] intoString:&str]) {
            [self _setLexText:str];
            if (shouldShowLexing)
                NSLog(@"%s [state=%lu], token = TK_TEMPLATE_TYPE (%@)", __cmd, state, lexText);
            return TK_TEMPLATE_TYPE;
        }

        NSLog(@"Ooops, fell through in template types state.");
    } else if (state == CDTypeLexerState_Identifier) {
        NSString *anIdentifier;

        //NSLog(@"Scanning in identifier state.");
        [scanner setCharactersToBeSkipped:nil];

        if ([scanner scanIdentifierIntoString:&anIdentifier]) {
            [self _setLexText:anIdentifier];
            if (shouldShowLexing)
                NSLog(@"%s [state=%lu], token = TK_IDENTIFIER (%@)", __cmd, state, lexText);
            state = CDTypeLexerState_Normal;
            return TK_IDENTIFIER;
        }
    } else {
        [scanner setCharactersToBeSkipped:nil];

        if ([scanner scanString:@"\"" intoString:NULL]) {
            if ([scanner scanUpToString:@"\"" intoString:&str])
                [self _setLexText:str];
            else
                [self _setLexText:@""];
            [scanner scanString:@"\"" intoString:NULL];
            if (shouldShowLexing)
                NSLog(@"%s [state=%lu], token = TK_QUOTED_STRING (%@)", __cmd, state, lexText);
            return TK_QUOTED_STRING;
        }

        if ([scanner my_scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&str]) {
            [self _setLexText:str];
            if (shouldShowLexing)
                NSLog(@"%s [state=%lu], token = TK_NUMBER (%@)", __cmd, state, lexText);
            return TK_NUMBER;
        }

        if ([scanner scanCharacter:&ch]) {
            if (shouldShowLexing)
                NSLog(@"%s [state=%lu], token = %d '%c'", __cmd, state, ch, ch);
            return ch;
        }
    }

    if (shouldShowLexing)
        NSLog(@"%s [state=%lu], token = TK_EOS", __cmd, state);

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

    if ([aScanner scanIdentifierIntoString:&anIdentifier]) {
        [aScanner release];
        return anIdentifier;
    }

    [aScanner release];

    return nil;
}

@end
