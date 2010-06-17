// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDTypeFormatter.h"

#include <assert.h>
#import "NSError-CDExtensions.h"
#import "NSScanner-Extensions.h"
#import "NSString-Extensions.h"
#import "CDClassDump.h" // not ideal
#import "CDMethodType.h"
#import "CDSymbolReferences.h"
#import "CDType.h"
#import "CDTypeLexer.h"
#import "CDTypeParser.h"
#import "CDTypeController.h"

static BOOL debug = NO;

@implementation CDTypeFormatter

- (id)init;
{
    if ([super init] == nil)
        return nil;

    nonretained_typeController = nil;

    flags.shouldExpand = NO;
    flags.shouldAutoExpand = NO;
    flags.shouldShowLexing = debug;

    return self;
}

- (CDTypeController *)typeController;
{
    return nonretained_typeController;
}

- (void)setTypeController:(CDTypeController *)newTypeController;
{
    nonretained_typeController = newTypeController;
}

@synthesize baseLevel;

- (BOOL)shouldExpand;
{
    return flags.shouldExpand;
}

- (void)setShouldExpand:(BOOL)newFlag;
{
    flags.shouldExpand = newFlag;
}

- (BOOL)shouldAutoExpand;
{
    return flags.shouldAutoExpand;
}

- (void)setShouldAutoExpand:(BOOL)newFlag;
{
    flags.shouldAutoExpand = newFlag;
}

- (BOOL)shouldShowLexing;
{
    return flags.shouldShowLexing;
}

- (void)setShouldShowLexing:(BOOL)newFlag;
{
    flags.shouldShowLexing = newFlag;
}

- (NSString *)_specialCaseVariable:(NSString *)name type:(NSString *)type;
{
    if ([type isEqual:@"c"]) {
        if (name == nil)
            return @"BOOL";
        else
            return [NSString stringWithFormat:@"BOOL %@", name];
#if 0
    } else if ([type isEqual:@"b1"]) {
        if (name == nil)
            return @"BOOL :1";
        else
            return [NSString stringWithFormat:@"BOOL %@:1", name];
#endif
    }

    return nil;
}

- (NSString *)_specialCaseVariable:(NSString *)name parsedType:(CDType *)type;
{
    if ([type type] == 'c') {
        if (name == nil)
            return @"BOOL";
        else
            return [NSString stringWithFormat:@"BOOL %@", name];
    }

    return nil;
}

// TODO (2004-01-28): See if we can pass in the actual CDType.
// TODO (2009-07-09): Now that we have the other method, see if we can use it instead.
- (NSString *)formatVariable:(NSString *)name type:(NSString *)type symbolReferences:(CDSymbolReferences *)symbolReferences;
{
    NSString *specialCase;
    CDTypeParser *aParser;
    CDType *resultType;
    NSError *error;

    // Special cases: char -> BOOLs, 1 bit ints -> BOOL too?
    specialCase = [self _specialCaseVariable:name type:type];
    if (specialCase != nil) {
        NSMutableString *resultString;

        resultString = [NSMutableString string];
        [resultString appendString:[NSString spacesIndentedToLevel:baseLevel spacesPerLevel:4]];
        [resultString appendString:specialCase];

        return resultString;
    }

    aParser = [[CDTypeParser alloc] initWithType:type];
    [[aParser lexer] setShouldShowLexing:flags.shouldShowLexing];
    resultType = [aParser parseType:&error];
    //NSLog(@"resultType: %p", resultType);

    if (resultType == nil) {
        NSLog(@"Couldn't parse type: %@", [error myExplanation]);
        [aParser release];
        //NSLog(@"<  %s", _cmd);
        return nil;
    }

    [aParser release];

    return [self formatVariable:name parsedType:resultType symbolReferences:symbolReferences];
}

- (NSString *)formatVariable:(NSString *)name parsedType:(CDType *)type symbolReferences:(CDSymbolReferences *)symbolReferences;
{
    NSString *specialCase;
    NSMutableString *resultString;

    resultString = [NSMutableString string];

    specialCase = [self _specialCaseVariable:name parsedType:type];
    [resultString appendSpacesIndentedToLevel:baseLevel spacesPerLevel:4];
    if (specialCase != nil) {
        [resultString appendString:specialCase];
    } else {
        // TODO (2009-08-26): Ideally, just formatting a type shouldn't change it.  These changes should be done before, but this is handy.
        [type setVariableName:name];
        [type phase0RecursivelyFixStructureNames:NO]; // Nuke the $_ names
        [type phase3MergeWithTypeController:[self typeController]];
        [resultString appendString:[type formattedString:nil formatter:self level:0 symbolReferences:symbolReferences]];
    }

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
        NSLog(@"Warning: Parsing method types failed, %@", methodName);
    [aParser release];

    if (methodTypes == nil || [methodTypes count] == 0) {
        return nil;
    }

    typeDict = [NSMutableDictionary dictionary];
    {
        NSUInteger count, index;
        BOOL noMoreTypes;
        CDMethodType *aMethodType;
        NSScanner *scanner;
        NSString *specialCase;

        count = [methodTypes count];
        index = 0;
        noMoreTypes = NO;

        aMethodType = [methodTypes objectAtIndex:index];
        specialCase = [self _specialCaseVariable:nil type:[[aMethodType type] bareTypeString]];
        if (specialCase != nil) {
            [typeDict setValue:specialCase forKey:@"return-type"];
        } else {
            NSString *str;

            str = [[aMethodType type] formattedString:nil formatter:self level:0 symbolReferences:symbolReferences];
            if (str != nil)
                [typeDict setValue:str forKey:@"return-type"];
        }

        index += 3;

        parameterTypes = [NSMutableArray array];
        [typeDict setValue:parameterTypes forKey:@"parametertypes"];

        scanner = [[NSScanner alloc] initWithString:methodName];
        while ([scanner isAtEnd] == NO) {
            NSString *str;

            // We can have unnamed parameters, :::
            if ([scanner scanUpToString:@":" intoString:&str]) {
                //NSLog(@"str += '%@'", str);
//				int unnamedCount, unnamedIndex;
//				unnamedCount = [str length];
//				for (unnamedIndex = 0; unnamedIndex < unnamedCount; unnamedIndex++)
//					[parameterTypes addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"", @"type", @"", @"name", nil]];
            }
            if ([scanner scanString:@":" intoString:NULL]) {
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
                        [parameter setValue:typeString forKey:@"type"];
                    }
                    //[parameter setValue:[NSString stringWithFormat:@"fp%@", [aMethodType offset]] forKey:@"name"];
                    [parameter setValue:[NSString stringWithFormat:@"arg%u", index-2] forKey:@"name"];
                    [parameterTypes addObject:parameter];
                    index++;
                }
            }
        }

        [scanner release];

        if (noMoreTypes) {
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
        NSLog(@"Warning: Parsing method types failed, %@", methodName);
    [aParser release];

    if (methodTypes == nil || [methodTypes count] == 0) {
        return nil;
    }

    resultString = [NSMutableString string];
    {
        NSUInteger count, index;
        BOOL noMoreTypes;
        CDMethodType *aMethodType;
        NSScanner *scanner;
        NSString *specialCase;

        count = [methodTypes count];
        index = 0;
        noMoreTypes = NO;

        aMethodType = [methodTypes objectAtIndex:index];
        [resultString appendString:@"("];
        specialCase = [self _specialCaseVariable:nil type:[[aMethodType type] bareTypeString]];
        if (specialCase != nil) {
            [resultString appendString:specialCase];
        } else {
            NSString *str;

            str = [[aMethodType type] formattedString:nil formatter:self level:0 symbolReferences:symbolReferences];
            if (str != nil)
                [resultString appendFormat:@"%@", str];
        }
        [resultString appendString:@")"];

        index += 3;

        scanner = [[NSScanner alloc] initWithString:methodName];
        while ([scanner isAtEnd] == NO) {
            NSString *str;

            // We can have unnamed paramenters, :::
            if ([scanner scanUpToString:@":" intoString:&str]) {
                //NSLog(@"str += '%@'", str);
                [resultString appendString:str];
            }
            if ([scanner scanString:@":" intoString:NULL]) {
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
                    //[resultString appendFormat:@"fp%@", [aMethodType offset]];
                    [resultString appendFormat:@"arg%u", index-2];

                    ch = [scanner peekCharacter];
                    // if next character is not ':' nor EOS then add space
                    if (ch != nil && [ch isEqual:@":"] == NO)
                        [resultString appendString:@" "];
                    index++;
                }
            }
        }

        [scanner release];

        if (noMoreTypes) {
            [resultString appendString:@" /* Error: Ran out of types for this method. */"];
        }
    }

    return resultString;
}

// Called from CDType, which gets a formatter but not a type controller.
- (CDType *)replacementForType:(CDType *)aType;
{
    return [nonretained_typeController typeFormatter:self replacementForType:aType];
}

// Called from CDType, which gets a formatter but not a type controller.
- (NSString *)typedefNameForStruct:(CDType *)structType level:(NSUInteger)level;
{
    return [nonretained_typeController typeFormatter:self typedefNameForStruct:structType level:level];
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> baseLevel: %u, shouldExpand: %u, shouldAutoExpand: %u, shouldShowLexing: %u, tc: %p",
                     NSStringFromClass([self class]), self,
                     baseLevel, flags.shouldExpand, flags.shouldAutoExpand, flags.shouldShowLexing, nonretained_typeController];
}

@end
