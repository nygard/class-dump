// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDBalanceFormatter.h"

#import "NSString-Extensions.h"

static BOOL debug = NO;

@implementation CDBalanceFormatter

- (id)initWithString:(NSString *)str;
{
    if ([super init] == nil)
        return nil;

    scanner = [[NSScanner alloc] initWithString:str];
    openCloseSet = [[NSCharacterSet characterSetWithCharactersInString:@"{}<>()"] retain];

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
    NSArray *pairs;
    NSString *pre;
    NSString *opens[] = { @"{", @"<", @"(", nil};
    NSString *closes[] = { @"}", @">", @")", nil};
    NSUInteger index;
    BOOL foundOpen = NO;
    BOOL foundClose = NO;

    pairs = [[NSArray alloc] initWithObjects:@"{}", @"<>", @"()", nil];

    while ([scanner isAtEnd] == NO) {
        if ([scanner scanUpToCharactersFromSet:openCloseSet intoString:&pre]) {
            if (debug) NSLog(@"pre = '%@'", pre);
            [result appendFormat:@"%@%@\n", [NSString spacesIndentedToLevel:level], pre];
        }
        if (debug) NSLog(@"remaining: '%@'", [[scanner string] substringFromIndex:[scanner scanLocation]]);

        foundOpen = foundClose = NO;
        for (index = 0; index < 3; index++) {
            if (debug) NSLog(@"Checking open %u: '%@'", index, opens[index]);
            if ([scanner scanString:opens[index] intoString:NULL]) {
                if (debug) NSLog(@"Start %@", opens[index]);
                [result appendSpacesIndentedToLevel:level];
                [result appendString:opens[index]];
                [result appendString:@"\n"];

                [self parse:opens[index] index:[scanner scanLocation] - 1 level:level + 1];

                [result appendSpacesIndentedToLevel:level];
                [result appendString:closes[index]];
                [result appendString:@"\n"];
                foundOpen = YES;
                break;
            }

            if (debug) NSLog(@"Checking close %u: '%@'", index, closes[index]);
            if ([scanner scanString:closes[index] intoString:NULL]) {
                if ([open isEqualToString:opens[index]]) {
                    if (debug) NSLog(@"End %@", closes[index]);
                } else {
                    NSLog(@"ERROR: Unmatched end %@", closes[index]);
                }
                foundClose = YES;
                break;
            }
        }

        if (foundOpen == NO && foundClose == NO) {
            if (debug) NSLog(@"Unknown @ %u: %@", [scanner scanLocation], [[scanner string] substringFromIndex:[scanner scanLocation]]);
            break;
        }

        if (foundClose)
            break;
    }

    [pairs release];
}

- (NSString *)format;
{
    [self parse:nil index:0 level:0];

    if (debug) NSLog(@"result:\n%@", result);

    return [NSString stringWithString:result];
}

@end
