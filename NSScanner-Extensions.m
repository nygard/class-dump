//
// $Id: NSScanner-Extensions.m,v 1.4 2004/01/06 01:51:58 nygard Exp $
//

//  This file is part of class-dump, a utility for exmaing the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import "NSScanner-Extensions.h"

#import <Foundation/Foundation.h>
#import "NSString-Extensions.h"

@implementation NSScanner (CDExtensions)

- (NSString *)peekCharacter;
{
    //[self skipCharacters];

    if ([self isAtEnd] == YES)
        return nil;

    return [[self string] substringWithRange:NSMakeRange([self scanLocation], 1)];
}

- (unichar)peekChar;
{
    return [[self string] characterAtIndex:[self scanLocation]];
}

- (BOOL)scanCharacter:(unichar *)value;
{
    unichar ch;

    //[self skipCharacters];

    if ([self isAtEnd] == YES)
        return NO;

    ch = [[self string] characterAtIndex:[self scanLocation]];
    if (value != NULL)
        *value = ch;

    [self setScanLocation:[self scanLocation] + 1];

    return YES;
}

- (BOOL)scanCharacterFromSet:(NSCharacterSet *)set intoString:(NSString **)value;
{
    unichar ch;

    //[self skipCharacters];

    if ([self isAtEnd] == YES)
        return NO;

    ch = [[self string] characterAtIndex:[self scanLocation]];
    if ([set characterIsMember:ch] == YES) {
        if (value != NULL) {
            *value = [NSString stringWithUnichar:ch];
        }

        [self setScanLocation:[self scanLocation] + 1];
        return YES;
    }

    return NO;
}

@end
