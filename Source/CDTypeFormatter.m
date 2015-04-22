// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDTypeFormatter.h"

#import "CDMethodType.h"
#import "CDType.h"
#import "CDTypeLexer.h"
#import "CDTypeParser.h"
#import "CDTypeController.h"

static BOOL debug = NO;

@interface CDTypeFormatter ()
@end

#pragma mark -

@implementation CDTypeFormatter
{
    __weak CDTypeController *_typeController;
    
    NSUInteger _baseLevel;
    
    BOOL _shouldExpand; // But just top level struct, level == 0
    BOOL _shouldAutoExpand;
    BOOL _shouldShowLexing;
}

- (id)init;
{
    if ((self = [super init])) {
        _typeController = nil;
        _baseLevel = 0;
        _shouldExpand = NO;
        _shouldAutoExpand = NO;
        _shouldShowLexing = debug;
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> baseLevel: %lu, shouldExpand: %u, shouldAutoExpand: %u, shouldShowLexing: %u, tc: %p",
            NSStringFromClass([self class]), self,
            self.baseLevel, self.shouldExpand, self.shouldAutoExpand, self.shouldShowLexing, self.typeController];
}

#pragma mark -

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
    if (type.primitiveType == 'c') {
        if (name == nil)
            return @"BOOL";
        else
            return [NSString stringWithFormat:@"BOOL %@", name];
    }

    return nil;
}

- (NSString *)formatVariable:(NSString *)name type:(CDType *)type;
{
    NSMutableString *resultString = [NSMutableString string];

    NSString *specialCase = [self _specialCaseVariable:name parsedType:type];
    [resultString appendSpacesIndentedToLevel:self.baseLevel spacesPerLevel:4];
    if (specialCase != nil) {
        [resultString appendString:specialCase];
    } else {
        // TODO: (2009-08-26) Ideally, just formatting a type shouldn't change it.  These changes should be done before, but this is handy.
        type.variableName = name;
        [type phase0RecursivelyFixStructureNames:NO]; // Nuke the $_ names
        [type phase3MergeWithTypeController:self.typeController];
        [resultString appendString:[type formattedString:nil formatter:self level:0]];
    }

    return resultString;
}

- (NSDictionary *)formattedTypesForMethodName:(NSString *)name type:(NSString *)type;
{
    CDTypeParser *parser = [[CDTypeParser alloc] initWithString:type];

    NSError *error = nil;
    NSArray *methodTypes = [parser parseMethodType:&error];
    if (methodTypes == nil)
        NSLog(@"Warning: Parsing method types failed, %@", name);

    if (methodTypes == nil || [methodTypes count] == 0) {
        return nil;
    }

    NSMutableDictionary *typeDict = [NSMutableDictionary dictionary];
    {
        NSUInteger count = [methodTypes count];
        NSUInteger index = 0;
        BOOL noMoreTypes = NO;

        CDMethodType *methodType = methodTypes[index];
        NSString *specialCase = [self _specialCaseVariable:nil type:methodType.type.bareTypeString];
        if (specialCase != nil) {
            [typeDict setValue:specialCase forKey:@"return-type"];
        } else {
            NSString *str = [[methodType type] formattedString:nil formatter:self level:0];
            if (str != nil)
                [typeDict setValue:str forKey:@"return-type"];
        }

        index += 3;

        NSMutableArray *parameterTypes = [NSMutableArray array];
        [typeDict setValue:parameterTypes forKey:@"parametertypes"];

        NSScanner *scanner = [[NSScanner alloc] initWithString:name];
        while ([scanner isAtEnd] == NO) {
            NSString *str;

            // We can have unnamed parameters, :::
            if ([scanner scanUpToString:@":" intoString:&str]) {
                //NSLog(@"str += '%@'", str);
//				int unnamedCount, unnamedIndex;
//				unnamedCount = [str length];
//				for (unnamedIndex = 0; unnamedIndex < unnamedCount; unnamedIndex++)
//					[parameterTypes addObject:@{ @"type": @"", @"name": @""}];
            }
            if ([scanner scanString:@":" intoString:NULL]) {
                if (index >= count) {
                    noMoreTypes = YES;
                } else {
                    NSMutableDictionary *parameter = [NSMutableDictionary dictionary];

                    methodType = methodTypes[index];
                    specialCase = [self _specialCaseVariable:nil type:methodType.type.bareTypeString];
                    if (specialCase != nil) {
                        [parameter setValue:specialCase forKey:@"type"];
                    } else {
                        NSString *typeString = [methodType.type formattedString:nil formatter:self level:0];
                        [parameter setValue:typeString forKey:@"type"];
                    }
                    //[parameter setValue:[NSString stringWithFormat:@"fp%@", methodType.offset] forKey:@"name"];
                    [parameter setValue:[NSString stringWithFormat:@"arg%lu", index-2] forKey:@"name"];
                    [parameterTypes addObject:parameter];
                    index++;
                }
            }
        }

        if (noMoreTypes) {
            NSLog(@" /* Error: Ran out of types for this method. */");
        }
    }

    return typeDict;
}

- (NSString *)formatMethodName:(NSString *)methodName typeString:(NSString *)typeString;
{
    CDTypeParser *parser = [[CDTypeParser alloc] initWithString:typeString];

    NSError *error = nil;
    NSArray *methodTypes = [parser parseMethodType:&error];
    if (methodTypes == nil)
        NSLog(@"Warning: Parsing method types failed, %@", methodName);

    if (methodTypes == nil || [methodTypes count] == 0) {
        return nil;
    }

    NSMutableString *resultString = [NSMutableString string];
    {
        NSUInteger count = [methodTypes count];
        NSUInteger index = 0;
        BOOL noMoreTypes = NO;

        CDMethodType *methodType = methodTypes[index];
        [resultString appendString:@"("];
        NSString *specialCase = [self _specialCaseVariable:nil type:methodType.type.bareTypeString];
        if (specialCase != nil) {
            [resultString appendString:specialCase];
        } else {
            NSString *str = [methodType.type formattedString:nil formatter:self level:0];
            if (str != nil)
                [resultString appendFormat:@"%@", str];
        }
        [resultString appendString:@")"];

        index += 3;

        NSScanner *scanner = [[NSScanner alloc] initWithString:methodName];
        while ([scanner isAtEnd] == NO) {
            NSString *str;

            // We can have unnamed paramenters, :::
            if ([scanner scanUpToString:@":" intoString:&str]) {
                //NSLog(@"str += '%@'", str);
                [resultString appendString:str];
            }
            if ([scanner scanString:@":" intoString:NULL]) {
                [resultString appendString:@":"];
                if (index >= count) {
                    noMoreTypes = YES;
                } else {
                    methodType = methodTypes[index];
                    specialCase = [self _specialCaseVariable:nil type:methodType.type.bareTypeString];
                    if (specialCase != nil) {
                        [resultString appendFormat:@"(%@)", specialCase];
                    } else {
                        NSString *formattedType = [methodType.type formattedString:nil formatter:self level:0];
                        //if ([[methodType type] isIDType] == NO)
                        [resultString appendFormat:@"(%@)", formattedType];
                    }
                    //[resultString appendFormat:@"fp%@", [methodType offset]];
                    [resultString appendFormat:@"arg%lu", index-2];

                    NSString *ch = [scanner peekCharacter];
                    // if next character is not ':' nor EOS then add space
                    if (ch != nil && [ch isEqual:@":"] == NO)
                        [resultString appendString:@" "];
                    index++;
                }
            }
        }

        if (noMoreTypes) {
            [resultString appendString:@" /* Error: Ran out of types for this method. */"];
        }
    }

    return resultString;
}

// Called from CDType, which gets a formatter but not a type controller.
- (CDType *)replacementForType:(CDType *)type;
{
    return [self.typeController typeFormatter:self replacementForType:type];
}

// Called from CDType, which gets a formatter but not a type controller.
- (NSString *)typedefNameForStructure:(CDType *)structureType level:(NSUInteger)level;
{
    return [self.typeController typeFormatter:self typedefNameForStructure:structureType level:level];
}

- (void)formattingDidReferenceClassName:(NSString *)name;
{
    [self.typeController typeFormatter:self didReferenceClassName:name];
}

- (void)formattingDidReferenceProtocolNames:(NSArray *)names;
{
    [self.typeController typeFormatter:self didReferenceProtocolNames:names];
}

@end
