//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import "CDTypeFormatter.h"

#import "rcsid.h"
#include <assert.h>
#import <Foundation/Foundation.h>
#import "NSScanner-Extensions.h"
#import "NSString-Extensions.h"
#import "CDClassDump.h" // not ideal
#import "CDMethodType.h"
#import "CDSymbolReferences.h"
#import "CDType.h"
#import "CDTypeLexer.h"
#import "CDTypeParser.h"

RCS_ID("$Header: /Volumes/Data/tmp/Tools/class-dump/CDTypeFormatter.m,v 1.27 2004/02/02 21:37:20 nygard Exp $");

//----------------------------------------------------------------------

@implementation CDTypeFormatter

- (BOOL)shouldExpand;
{
    return shouldExpand;
}

- (void)setShouldExpand:(BOOL)newFlag;
{
    shouldExpand = newFlag;
}

- (BOOL)shouldAutoExpand;
{
    return shouldAutoExpand;
}

- (void)setShouldAutoExpand:(BOOL)newFlag;
{
    shouldAutoExpand = newFlag;
}

- (BOOL)shouldShowLexing;
{
    return shouldShowLexing;
}

- (void)setShouldShowLexing:(BOOL)newFlag;
{
    shouldShowLexing = newFlag;
}

- (int)baseLevel;
{
    return baseLevel;
}

- (void)setBaseLevel:(int)newBaseLevel;
{
    baseLevel = newBaseLevel;
}

- (id)delegate;
{
    return nonretainedDelegate;
}

- (void)setDelegate:(id)newDelegate;
{
    nonretainedDelegate = newDelegate;
}

- (NSString *)_specialCaseVariable:(NSString *)name type:(NSString *)type;
{
#if 0
    if ([type isEqual:@"c"] == YES) {
        if (name == nil)
            return @"BOOL";
        else
            return [NSString stringWithFormat:@"BOOL %@", name];
    } else if ([type isEqual:@"b1"] == YES) {
        if (name == nil)
            return @"BOOL :1";
        else
            return [NSString stringWithFormat:@"BOOL %@:1", name];
    }
#endif
    return nil;
}

// TODO (2004-01-28): See if we can pass in the actual CDType.
- (NSString *)formatVariable:(NSString *)name type:(NSString *)type symbolReferences:(CDSymbolReferences *)symbolReferences;
{
    CDTypeParser *aParser;
    CDType *resultType;
    NSMutableString *resultString;
    NSString *specialCase;

    //NSLog(@"%s, shouldExpandStructures: %d", _cmd, shouldExpandStructures);
    //NSLog(@" > %s", _cmd);
    //NSLog(@"name: '%@', type: '%@', level: %d", name, type, level);

    // Special cases: char -> BOOLs, 1 bit ints -> BOOL too?
    specialCase = [self _specialCaseVariable:name type:type];
    if (specialCase != nil) {
        resultString = [NSMutableString string];
        [resultString appendString:[NSString spacesIndentedToLevel:baseLevel spacesPerLevel:4]];
        [resultString appendString:specialCase];

        return resultString;
    }

    aParser = [[CDTypeParser alloc] initWithType:type];
    [[aParser lexer] setShouldShowLexing:shouldShowLexing];
    resultType = [aParser parseType];
    //NSLog(@"resultType: %p", resultType);

    if (resultType == nil) {
        [aParser release];
        //NSLog(@"<  %s", _cmd);
        return nil;
    }

    resultString = [NSMutableString string];
    [resultType setVariableName:name];
    [resultString appendString:[NSString spacesIndentedToLevel:baseLevel spacesPerLevel:4]];
    [resultString appendString:[resultType formattedString:nil formatter:self level:0 symbolReferences:symbolReferences]];

    //free_allocated_methods();
    //free_allocated_types();
    [aParser release];

    //NSLog(@"<  %s", _cmd);
    return resultString;
}

- (NSString *)formatMethodName:(NSString *)methodName type:(NSString *)type symbolReferences:(CDSymbolReferences *)symbolReferences;
{
    CDTypeParser *aParser;
    NSArray *methodTypes;
    NSMutableString *resultString;

    aParser = [[CDTypeParser alloc] initWithType:type];
    methodTypes = [aParser parseMethodType];
    if (methodTypes == nil)
        NSLog(@"Warning: Parsing method types failed, %@", methodName);
    [aParser release];

    if (methodTypes == nil || [methodTypes count] == 0) {
        return nil;
    }

    resultString = [NSMutableString string];
    {
        int count, index;
        BOOL noMoreTypes;
        CDMethodType *aMethodType;
        NSScanner *scanner;
        NSString *specialCase;

        count = [methodTypes count];
        index = 0;
        noMoreTypes = NO;

        aMethodType = [methodTypes objectAtIndex:index];
        if ([[aMethodType type] isIDType] == NO) {
            NSString *str;

            [resultString appendString:@"("];
            specialCase = [self _specialCaseVariable:nil type:[[aMethodType type] bareTypeString]];
            if (specialCase != nil) {
                [resultString appendString:specialCase];
            } else {
                str = [[aMethodType type] formattedString:nil formatter:self level:0 symbolReferences:symbolReferences];
                if (str != nil)
                    [resultString appendFormat:@"%@", str];
            }
            [resultString appendString:@")"];
        }

        index += 3;

        scanner = [[NSScanner alloc] initWithString:methodName];
        while ([scanner isAtEnd] == NO) {
            NSString *str;

            // We can have unnamed paramenters, :::
            if ([scanner scanUpToString:@":" intoString:&str] == YES) {
                //NSLog(@"str += '%@'", str);
                [resultString appendString:str];
            }
            if ([scanner scanString:@":" intoString:NULL] == YES) {
                NSString *typeString;

                [resultString appendString:@":"];
                if (index >= count) {
                    noMoreTypes = YES;
                } else {
                    NSString *ch;

                    aMethodType = [methodTypes objectAtIndex:index];
                    specialCase = [self _specialCaseVariable:nil type:[[aMethodType type] bareTypeString]];
                    if (specialCase != nil) {
                        [resultString appendFormat:@"(%@)", specialCase];
                    } else {
                        typeString = [[aMethodType type] formattedString:nil formatter:self level:0 symbolReferences:symbolReferences];
                        if ([[aMethodType type] isIDType] == NO)
                            [resultString appendFormat:@"(%@)", typeString];
                    }
                    [resultString appendFormat:@"fp%@", [aMethodType offset]];

                    ch = [scanner peekCharacter];
                    // if next character is not ':' nor EOS then add space
                    if (ch != nil && [ch isEqual:@":"] == NO)
                        [resultString appendString:@" "];
                    index++;
                }
            }
        }

        if (noMoreTypes == YES) {
            NSLog(@" /* Error: Ran out of types for this method. */");
        }
    }

    return resultString;
}

- (CDType *)replacementForType:(CDType *)aType;
{
    //NSLog(@"[%p] %s, aType: %@", self, _cmd, [aType typeString]);
    if ([nonretainedDelegate respondsToSelector:@selector(typeFormatter:replacementForType:)] == YES) {
        return [nonretainedDelegate typeFormatter:self replacementForType:aType];
    }

    return nil;
}

- (NSString *)typedefNameForStruct:(CDType *)structType level:(int)level;
{
    if ([nonretainedDelegate respondsToSelector:@selector(typeFormatter:typedefNameForStruct:level:)] == YES)
        return [nonretainedDelegate typeFormatter:self typedefNameForStruct:structType level:level];

    return nil;
}

@end
