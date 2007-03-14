//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2006  Steve Nygard

#import "CDTypeFormatter.h"

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
    if ([type isEqual:@"c"] == YES) {
        if (name == nil)
            return @"BOOL";
        else
            return [NSString stringWithFormat:@"BOOL %@", name];
#if 0
    } else if ([type isEqual:@"b1"] == YES) {
        if (name == nil)
            return @"BOOL :1";
        else
            return [NSString stringWithFormat:@"BOOL %@:1", name];
#endif
    }

    return nil;
}

- (NSDictionary *)formattedTypeComponentsForType:(NSString *)type symbolReferences:(CDSymbolReferences *)symbolReferences;
{
    CDTypeParser *aParser;
    CDType *resultType;
    NSString *resultString;
    NSString *specialCase;
    NSError *error;
    NSArray *typeComponents;
    NSDictionary *resultDict;

    //NSLog(@"%s, shouldExpandStructures: %d", _cmd, shouldExpandStructures);
    //NSLog(@" > %s", _cmd);
    //NSLog(@"name: '%@', type: '%@', level: %d", name, type, level);

    // Special cases: char -> BOOLs, 1 bit ints -> BOOL too?
    specialCase = [self _specialCaseVariable:nil type:type];
    if (specialCase != nil) {
        // TODO: this works, because _specialCaseVariable:type: always returns just BOOL at the moment
        return [NSDictionary dictionaryWithObject:specialCase forKey:@"type"];
    }

    aParser = [[CDTypeParser alloc] initWithType:type];
    [[aParser lexer] setShouldShowLexing:shouldShowLexing];
    resultType = [aParser parseType:&error];
    //NSLog(@"resultType: %p", resultType);

    if (resultType == nil) {
        [aParser release];
        //NSLog(@"<  %s", _cmd);
        return nil;
    }

    // special marker '|' used as name, as that character surely is invalid as a declarator
    // we split on that to find out if there is a "type suffix" like bitfield length in the type string
    resultString = [resultType formattedString:@"|" formatter:self level:0 symbolReferences:symbolReferences];
    typeComponents = [resultString componentsSeparatedByString:@"|"];
    // there should never be more than two parts!
    assert([typeComponents count] == 2);
    if ([typeComponents count] == 2) {
        NSString *suffix = [typeComponents objectAtIndex:1];
        resultDict = [NSMutableDictionary dictionaryWithObject:[(NSString *)[typeComponents objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
                                          forKey:@"type"];
        if ([suffix length] != 0)
            [resultDict setValue:suffix forKey:@"typesuffix"];
    }
    [aParser release];

    //NSLog(@"<  %s", _cmd);
    return resultDict;
}

// TODO (2004-01-28): See if we can pass in the actual CDType.
- (NSString *)formatVariable:(NSString *)name type:(NSString *)type symbolReferences:(CDSymbolReferences *)symbolReferences;
{
    CDTypeParser *aParser;
    CDType *resultType;
    NSMutableString *resultString;
    NSString *specialCase;
    NSError *error;

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
    resultType = [aParser parseType:&error];
    //NSLog(@"resultType: %p", resultType);

    if (resultType == nil) {
        NSLog(@"Error: %@", error);
        [aParser release];
        //NSLog(@"<  %s", _cmd);
        return nil;
    }

    resultString = [NSMutableString string];
    [resultType setVariableName:name];
    [resultString appendString:[NSString spacesIndentedToLevel:baseLevel spacesPerLevel:4]];
    [resultString appendString:[resultType formattedString:nil formatter:self level:0 symbolReferences:symbolReferences]];

    [aParser release];

    //NSLog(@"<  %s", _cmd);
    return resultString;
}

- (NSDictionary *)formattedTypesForMethodName:(NSString *)methodName type:(NSString *)type symbolReferences:(CDSymbolReferences *)symbolReferences;
{
    CDTypeParser *aParser;
    NSArray *methodTypes;
    NSError *error;
    NSMutableDictionary *typeDict;
    NSMutableArray *parameterTypes;

    aParser = [[CDTypeParser alloc] initWithType:type];
    methodTypes = [aParser parseMethodType:&error];
    if (methodTypes == nil)
        NSLog(@"Warning: Parsing method types failed, %@, %@", methodName, error);
    [aParser release];

    if (methodTypes == nil || [methodTypes count] == 0) {
        return nil;
    }

    typeDict = [NSMutableDictionary dictionary];
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
        /*if ([[aMethodType type] isIDType] == NO)*/ {
            NSString *str;

            specialCase = [self _specialCaseVariable:nil type:[[aMethodType type] bareTypeString]];
            if (specialCase != nil) {
                [typeDict setValue:specialCase forKey:@"returntype"];
            } else {
                str = [[aMethodType type] formattedString:nil formatter:self level:0 symbolReferences:symbolReferences];
                if (str != nil)
                    [typeDict setValue:str forKey:@"returntype"];
            }
        }

        index += 3;

        parameterTypes = [NSMutableArray array];
        [typeDict setValue:parameterTypes forKey:@"parametertypes"];

        scanner = [[NSScanner alloc] initWithString:methodName];
        while ([scanner isAtEnd] == NO) {
            NSString *str;

            // We can have unnamed paramenters, :::
            if ([scanner scanUpToString:@":" intoString:&str] == YES) {
                //NSLog(@"str += '%@'", str);
//				int unnamedCount, unnamedIndex;
//				unnamedCount = [str length];
//				for (unnamedIndex = 0; unnamedIndex < unnamedCount; unnamedIndex++)
//					[parameterTypes addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"", @"type", @"", @"name", nil]];
            }
            if ([scanner scanString:@":" intoString:NULL] == YES) {
                NSString *typeString;

                if (index >= count) {
                    noMoreTypes = YES;
                } else {
                    NSMutableDictionary *parameter = [NSMutableDictionary dictionary];

                    aMethodType = [methodTypes objectAtIndex:index];
                    specialCase = [self _specialCaseVariable:nil type:[[aMethodType type] bareTypeString]];
                    if (specialCase != nil) {
                        [parameter setValue:specialCase forKey:@"type"];
                    } else {
                        typeString = [[aMethodType type] formattedString:nil formatter:self level:0 symbolReferences:symbolReferences];
                        //if ([[aMethodType type] isIDType] == NO)
                        [parameter setValue:typeString forKey:@"type"];
                    }
                    [parameter setValue:[NSString stringWithFormat:@"fp%@", [aMethodType offset]] forKey:@"name"];
                    [parameterTypes addObject:parameter];
                    index++;
                }
            }
        }

        if (noMoreTypes == YES) {
            NSLog(@" /* Error: Ran out of types for this method. */");
        }
    }

    return typeDict;
}

- (NSString *)formatMethodName:(NSString *)methodName type:(NSString *)type symbolReferences:(CDSymbolReferences *)symbolReferences;
{
    CDTypeParser *aParser;
    NSArray *methodTypes;
    NSMutableString *resultString;
    NSError *error;

    aParser = [[CDTypeParser alloc] initWithType:type];
    methodTypes = [aParser parseMethodType:&error];
    if (methodTypes == nil)
        NSLog(@"Warning: Parsing method types failed, %@, %@", methodName, error);
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
        /*if ([[aMethodType type] isIDType] == NO)*/ {
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
                        //if ([[aMethodType type] isIDType] == NO)
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
            [resultString appendString:@" /* Error: Ran out of types for this method. */"];
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
