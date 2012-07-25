// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDTypeLexer.h"

static BOOL debug = NO;

static NSString *CDTypeLexerStateName(CDTypeLexerState state)
{
    switch (state) {
        case CDTypeLexerState_Normal:        return @"Normal";
        case CDTypeLexerState_Identifier:    return @"Identifier";
        case CDTypeLexerState_TemplateTypes: return @"Template";
    }
}

@implementation CDTypeLexer
{
    NSScanner *_scanner;
    CDTypeLexerState _state;
    NSString *_lexText;
    
    BOOL _shouldShowLexing;
}

- (id)initWithString:(NSString *)string;
{
    if ((self = [super init])) {
        _scanner = [[NSScanner alloc] initWithString:string];
        [_scanner setCharactersToBeSkipped:nil];
        _state = CDTypeLexerState_Normal;
        _shouldShowLexing = debug;
    }

    return self;
}

#pragma mark -

- (void)setState:(CDTypeLexerState)newState;
{
    if (debug) NSLog(@"CDTypeLexer - changing state from %lu (%@) to %lu (%@)", _state, CDTypeLexerStateName(_state), newState, CDTypeLexerStateName(newState));
    _state = newState;
}

- (NSString *)string;
{
    return [self.scanner string];
}

- (int)scanNextToken;
{
    NSString *str;
    unichar ch;

    self.lexText = nil;

    if ([self.scanner isAtEnd]) {
        if (self.shouldShowLexing)                       NSLog(@"%s [state=%lu], token = TK_EOS", __cmd, self.state);
        return TK_EOS;
    }

    if (self.state == CDTypeLexerState_TemplateTypes) {
        // Skip whitespace, scan '<', ',', '>'.  Everything else is lumped together as a string.
        [self.scanner setCharactersToBeSkipped:[NSCharacterSet whitespaceCharacterSet]];
        if ([self.scanner scanString:@"<" intoString:NULL]) {
            if (self.shouldShowLexing)                   NSLog(@"%s [state=%lu], token = %d '%c'", __cmd, self.state, '<', '<');
            return '<';
        }

        if ([self.scanner scanString:@">" intoString:NULL]) {
            if (self.shouldShowLexing)                   NSLog(@"%s [state=%lu], token = %d '%c'", __cmd, self.state, '>', '>');
            return '>';
        }

        if ([self.scanner scanString:@"," intoString:NULL]) {
            if (self.shouldShowLexing)                   NSLog(@"%s [state=%lu], token = %d '%c'", __cmd, self.state, ',', ',');
            return ',';
        }

        if ([self.scanner my_scanCharactersFromSet:[NSScanner cdTemplateTypeCharacterSet] intoString:&str]) {
            self.lexText = str;
            if (self.shouldShowLexing)                   NSLog(@"%s [state=%lu], token = TK_TEMPLATE_TYPE (%@)", __cmd, self.state, self.lexText);
            return TK_TEMPLATE_TYPE;
        }

        NSLog(@"Ooops, fell through in template types state.");
    } else if (self.state == CDTypeLexerState_Identifier) {
        NSString *identifier;

        //NSLog(@"Scanning in identifier state.");
        [self.scanner setCharactersToBeSkipped:nil];

        if ([self.scanner scanIdentifierIntoString:&identifier]) {
            self.lexText = identifier;
            if (self.shouldShowLexing)                   NSLog(@"%s [state=%lu], token = TK_IDENTIFIER (%@)", __cmd, self.state, self.lexText);
            self.state = CDTypeLexerState_Normal;
            return TK_IDENTIFIER;
        }
    } else {
        [self.scanner setCharactersToBeSkipped:nil];

        if ([self.scanner scanString:@"\"" intoString:NULL]) {
            if ([self.scanner scanUpToString:@"\"" intoString:&str])
                self.lexText = str;
            else
                self.lexText = @"";

            [self.scanner scanString:@"\"" intoString:NULL];
            if (self.shouldShowLexing)                   NSLog(@"%s [state=%lu], token = TK_QUOTED_STRING (%@)", __cmd, self.state, self.lexText);
            return TK_QUOTED_STRING;
        }

        if ([self.scanner my_scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&str]) {
            self.lexText = str;
            if (self.shouldShowLexing)                   NSLog(@"%s [state=%lu], token = TK_NUMBER (%@)", __cmd, self.state, self.lexText);
            return TK_NUMBER;
        }

        if ([self.scanner scanCharacter:&ch]) {
            if (self.shouldShowLexing)                   NSLog(@"%s [state=%lu], token = %d '%c'", __cmd, self.state, ch, ch);
            return ch;
        }
    }

    if (self.shouldShowLexing)                           NSLog(@"%s [state=%lu], token = TK_EOS", __cmd, self.state);

    return TK_EOS;
}

- (unichar)peekChar;
{
    return [self.scanner peekChar];
}

- (NSString *)remainingString;
{
    return [[self.scanner string] substringFromIndex:[self.scanner scanLocation]];
}

- (NSString *)peekIdentifier;
{
    NSScanner *peekScanner = [[NSScanner alloc] initWithString:[self.scanner string]];
    [peekScanner setScanLocation:[self.scanner scanLocation]];

    NSString *identifier;
    if ([peekScanner scanIdentifierIntoString:&identifier]) {
        return identifier;
    }

    return nil;
}

@end
