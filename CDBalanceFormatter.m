// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import "CDBalanceFormatter.h"

#import "NSString-Extensions.h"

static BOOL debug = NO;

@implementation CDBalanceFormatter

- (id)initWithString:(NSString *)str;
{
    if ([super init] == nil)
        return nil;

    scanner = [[NSScanner alloc] initWithString:str];
    openCloseSet = [[NSCharacterSet characterSetWithCharactersInString:@"{}<>"] retain];

    result = [[NSMutableString alloc] init];

    return self;
}

- (void)dealloc;
{
    [scanner release];
    [openCloseSet release];

    [result release];

    [super dealloc];
}

- (void)parse:(NSString *)open index:(NSUInteger)openIndex level:(NSUInteger)level;
{
    NSString *pre;

    while ([scanner isAtEnd] == NO) {
        if ([scanner scanUpToCharactersFromSet:openCloseSet intoString:&pre]) {
            if (debug) NSLog(@"pre = '%@'", pre);
            [result appendFormat:@"%@%@\n", [NSString spacesIndentedToLevel:level], pre];
        }

        if ([scanner scanString:@"{" intoString:NULL]) {
            if (debug) NSLog(@"Start {");
            [result appendFormat:@"%@{\n", [NSString spacesIndentedToLevel:level]];
            [self parse:@"{" index:[scanner scanLocation] - 1 level:level + 1];
            [result appendFormat:@"%@}\n", [NSString spacesIndentedToLevel:level]];
        } else if ([scanner scanString:@"}" intoString:NULL]) {
            if ([open isEqualToString:@"{"]) {
                if (debug) NSLog(@"End }");
                break;
            } else {
                NSLog(@"ERROR: Unmatched end }");
            }
        } else if ([scanner scanString:@"<" intoString:NULL]) {
            if (debug) NSLog(@"Start <");
            [result appendFormat:@"%@<\n", [NSString spacesIndentedToLevel:level]];
            [self parse:@"<" index:[scanner scanLocation] - 1 level:level + 1];
            [result appendFormat:@"%@>\n", [NSString spacesIndentedToLevel:level]];
        } else if ([scanner scanString:@">" intoString:NULL]) {
            if ([open isEqualToString:@"<"]) {
                if (debug) NSLog(@"End >");
                break;
            } else {
                NSLog(@"ERROR: Unmatched end >");
            }
        } else {
            if (debug) NSLog(@"Unknown @ %u: %@", [scanner scanLocation], [[scanner string] substringFromIndex:[scanner scanLocation]]);
            break;
        }
    }
}

- (void)format;
{
    NSString *pre;
    NSUInteger level = 0;

    if ([scanner scanUpToCharactersFromSet:openCloseSet intoString:&pre]) {
        if (debug) NSLog(@"pre = '%@'", pre);
        [result appendFormat:@"%@\n", pre];
    }

    if ([scanner scanString:@"{" intoString:NULL]) {
        if (debug) NSLog(@"Start {");
        [result appendFormat:@"{\n"];
        [self parse:@"{" index:[scanner scanLocation] - 1 level:level + 1];
        [result appendFormat:@"}\n"];
    } else if ([scanner scanString:@"}" intoString:NULL]) {
        NSLog(@"ERROR: Unmatched end }");
    } else if ([scanner scanString:@"<" intoString:NULL]) {
        if (debug) NSLog(@"Start <");
        [result appendFormat:@"<\n"];
        [self parse:@"<" index:[scanner scanLocation] - 1 level:level + 1];
        [result appendFormat:@">\n"];
    } else if ([scanner scanString:@">" intoString:NULL]) {
        NSLog(@"ERROR: Unmatched end >");
    }

    if (debug) NSLog(@"result:\n%@", result);
}

@end
