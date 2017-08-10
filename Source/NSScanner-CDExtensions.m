// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "NSScanner-CDExtensions.h"

@implementation NSScanner (CDExtensions)

// other: $_:*
// start: alpha + other
// remainder: alnum + other

+ (NSCharacterSet *)cdOtherCharacterSet;
{
    static NSCharacterSet *otherCharacterSet = nil;

    if (otherCharacterSet == nil)
        otherCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"$_:*"];

    return otherCharacterSet;
}

+ (NSCharacterSet *)cdIdentifierStartCharacterSet;
{
    static NSCharacterSet *identifierStartCharacterSet = nil;

    if (identifierStartCharacterSet == nil) {
        NSMutableCharacterSet *set = [[NSCharacterSet letterCharacterSet] mutableCopy];
        [set formUnionWithCharacterSet:[NSScanner cdOtherCharacterSet]];
        identifierStartCharacterSet = [set copy];
    }

    return identifierStartCharacterSet;
}

+ (NSCharacterSet *)cdIdentifierCharacterSet;
{
    static NSCharacterSet *identifierCharacterSet = nil;

    if (identifierCharacterSet == nil) {
        NSMutableCharacterSet *set = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
        [set formUnionWithCharacterSet:[NSScanner cdOtherCharacterSet]];
        identifierCharacterSet = [set copy];
    }

    return identifierCharacterSet;
}

+ (NSCharacterSet *)cdTemplateTypeCharacterSet;
{
    static NSCharacterSet *templateTypeCharacterSet = nil;

    if (templateTypeCharacterSet == nil)
        templateTypeCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"<,>"] invertedSet];

    return templateTypeCharacterSet;
}

- (NSString *)peekCharacter;
{
    //[self skipCharacters];

    if ([self isAtEnd])
        return nil;

    return [[self string] substringWithRange:NSMakeRange([self scanLocation], 1)];
}

- (unichar)peekChar;
{
    return [[self string] characterAtIndex:[self scanLocation]];
}

- (BOOL)scanCharacter:(unichar *)value;
{
    //[self skipCharacters];

    if ([self isAtEnd])
        return NO;

    unichar ch = [[self string] characterAtIndex:[self scanLocation]];
    if (value != NULL)
        *value = ch;

    [self setScanLocation:[self scanLocation] + 1];

    return YES;
}

- (BOOL)scanCharacterFromSet:(NSCharacterSet *)set intoString:(NSString *__autoreleasing *)value;
{
    //[self skipCharacters];

    if ([self isAtEnd])
        return NO;

    unichar ch = [[self string] characterAtIndex:[self scanLocation]];
    if ([set characterIsMember:ch]) {
        if (value != NULL) {
            *value = [NSString stringWithUnichar:ch];
        }

        [self setScanLocation:[self scanLocation] + 1];
        return YES;
    }

    return NO;
}

// On 10.3 (7D24) the Foundation scanCharactersFromSet:intoString: inverts the set each call, creating an autoreleased CFCharacterSet.
// This cuts the total CFCharacterSet allocations (when run on Foundation) from 161682 down to 17.

// This works for my purposes, but I haven't tested it to make sure it's fully compatible with the standard version.

- (BOOL)my_scanCharactersFromSet:(NSCharacterSet *)set intoString:(NSString *__autoreleasing *)value;
{
    NSUInteger currentLocation = [self scanLocation];

    // Skip over characters
    NSCharacterSet *skipSet = [self charactersToBeSkipped];
    while ([self isAtEnd] == NO) {
        unichar ch = [[self string] characterAtIndex:currentLocation];
        if ([skipSet characterIsMember:ch] == NO)
            break;

        currentLocation++;
        [self setScanLocation:currentLocation];
    }

    NSRange matchedRange = NSMakeRange(currentLocation, 0);

    while ([self isAtEnd] == NO) {
        unichar ch = [[self string] characterAtIndex:currentLocation];
        if ([set characterIsMember:ch] == NO)
            break;

        currentLocation++;
        [self setScanLocation:currentLocation];
    }

    matchedRange.length = currentLocation - matchedRange.location;

    if (matchedRange.length == 0)
        return NO;

    if (value != NULL) {
        *value = [[self string] substringWithRange:matchedRange];
    }

    return YES;
}

- (BOOL)scanIdentifierIntoString:(NSString *__autoreleasing *)stringPointer;
{
    NSString *start, *remainder;

    if ([self scanString:@"?" intoString:stringPointer]) {
        return YES;
    }

    if ([self scanCharacterFromSet:[NSScanner cdIdentifierStartCharacterSet] intoString:&start]) {
        NSString *str;

        if ([self my_scanCharactersFromSet:[NSScanner cdIdentifierCharacterSet] intoString:&remainder]) {
            str = [start stringByAppendingString:remainder];
        } else {
            str = start;
        }

        if (stringPointer != NULL)
            *stringPointer = str;

        return YES;
    }

    return NO;
}

@end
