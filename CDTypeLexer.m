//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import "CDTypeLexer.h"

#import "rcsid.h"
#import <Foundation/Foundation.h>
#import "NSScanner-Extensions.h"

RCS_ID("$Header: /Volumes/Data/tmp/Tools/class-dump/CDTypeLexer.m,v 1.10 2004/01/18 00:42:52 nygard Exp $");

@implementation CDTypeLexer

// other: $_:*
// start: alpha + other
// remainder: alnum + other

+ (NSCharacterSet *)otherCharacterSet;
{
    static NSCharacterSet *otherCharacterSet = nil;

    if (otherCharacterSet == nil)
        otherCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"$_:*"] retain];

    return otherCharacterSet;
}

+ (NSCharacterSet *)identifierStartCharacterSet;
{
    static NSCharacterSet *identifierStartCharacterSet = nil;

    if (identifierStartCharacterSet == nil) {
        NSMutableCharacterSet *aSet;

        aSet = [[NSCharacterSet letterCharacterSet] mutableCopy];
        [aSet formUnionWithCharacterSet:[CDTypeLexer otherCharacterSet]];
        identifierStartCharacterSet = [aSet copy];

        [aSet release];
    }

    return identifierStartCharacterSet;
}

+ (NSCharacterSet *)identifierCharacterSet;
{
    static NSCharacterSet *identifierCharacterSet = nil;

    if (identifierCharacterSet == nil) {
        NSMutableCharacterSet *aSet;

        aSet = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
        [aSet formUnionWithCharacterSet:[CDTypeLexer otherCharacterSet]];
        identifierCharacterSet = [aSet copy];

        [aSet release];
    }

    return identifierCharacterSet;
}

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

// TODO: Change to scanNextToken?
- (int)nextToken;
{
    NSString *str;
    unichar ch;

    [self _setLexText:nil];

    if ([scanner isAtEnd] == YES) {
        if (shouldShowLexing == YES)
            NSLog(@"%s [id=%d], token = TK_EOS", _cmd, isInIdentifierState);
        return TK_EOS;
    }

    if (isInIdentifierState == YES) {
        NSString *start, *remainder;

        //NSLog(@"Scanning in identifier state.");

        if ([scanner scanString:@"?" intoString:NULL] == YES) {
            [self _setLexText:@"?"];
            [self setIsInIdentifierState:NO];
            if (shouldShowLexing == YES)
                NSLog(@"%s [id=%d], token = TK_IDENTIFIER (%@)", _cmd, isInIdentifierState, lexText);
            return TK_IDENTIFIER;
        }

        if ([scanner scanString:@"\"" intoString:NULL] == YES) {
            [self setIsInIdentifierState:NO];
            if (shouldShowLexing == YES)
                NSLog(@"%s [id=%d], token = %d '%c'", _cmd, isInIdentifierState, '"', '"');
            return '"';
        }

        if ([scanner scanCharacterFromSet:[CDTypeLexer identifierStartCharacterSet] intoString:&start] == YES) {
            if ([scanner scanCharactersFromSet:[CDTypeLexer identifierCharacterSet] intoString:&remainder] == YES) {
                str = [start stringByAppendingString:remainder];
            } else {
                str = start;
            }

            [self setIsInIdentifierState:NO];
            [self _setLexText:str];
            if (shouldShowLexing == YES)
                NSLog(@"%s [id=%d], token = TK_IDENTIFIER (%@)", _cmd, isInIdentifierState, lexText);
            return TK_IDENTIFIER;
        }
    }

    if ([scanner scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&str] == YES) {
        [self _setLexText:str];
        if (shouldShowLexing == YES)
            NSLog(@"%s [id=%d], token = TK_NUMBER (%@)", _cmd, isInIdentifierState, lexText);
        return TK_NUMBER;
    }

    if ([scanner scanCharacter:&ch] == YES) {
        // TODO: I'm just assuming this works.
        if (shouldShowLexing == YES)
            NSLog(@"%s [id=%d], token = %d '%c'", _cmd, isInIdentifierState, ch, ch);
        return ch;
    }

    if (shouldShowLexing == YES)
        NSLog(@"%s [id=%d], token = TK_EOS)", _cmd, isInIdentifierState);

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

@end
