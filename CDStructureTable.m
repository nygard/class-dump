//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import "CDStructureTable.h"

#import "rcsid.h"
#import <Foundation/Foundation.h>
#import "CDType.h"
#import "CDTypeFormatter.h"
#import "CDTypeParser.h"

RCS_ID("$Header: /Volumes/Data/tmp/Tools/class-dump/CDStructureTable.m,v 1.6 2004/01/12 19:36:14 nygard Exp $");

@implementation CDStructureTable

- (id)init;
{
    if ([super init] == nil)
        return nil;

    structuresByName = [[NSMutableDictionary alloc] init];

    anonymousStructureCountsByType = [[NSMutableDictionary alloc] init];
    anonymousStructuresByType = [[NSMutableDictionary alloc] init];
    anonymousStructureNamesByType = [[NSMutableDictionary alloc] init];

    replacementTypes = [[NSMutableDictionary alloc] init];
    forcedTypedefs = [[NSMutableSet alloc] init];

    anonymousBaseName = nil;

    return self;
}

- (void)dealloc;
{
    [structuresByName release];

    [anonymousStructureCountsByType release];
    [anonymousStructuresByType release];
    [anonymousStructureNamesByType release];

    [replacementTypes release];
    [forcedTypedefs release];
    [anonymousBaseName release];

    [super dealloc];
}

- (NSString *)anonymousBaseName;
{
    return anonymousBaseName;
}

- (void)setAnonymousBaseName:(NSString *)newName;
{
    if (newName == anonymousBaseName)
        return;

    [anonymousBaseName release];
    anonymousBaseName = [newName retain];
}

- (BOOL)shouldDebug;
{
    return flags.shouldDebug;
}

- (void)setShouldDebug:(BOOL)newFlag;
{
    flags.shouldDebug = newFlag;
}

- (void)doneRegistration;
{
    NSLog(@"[%p] ============================================================", self);
    // Check for isomorphic structs, one of which may not have had named members
    [self processIsomorphicStructures];
    [self generateNamesForAnonymousStructures];

    [self logStructureCounts];
    [self logReplacementTypes];
    [self logNamedStructures];
    [self logAnonymousStructures];
    [self logForcedTypedefs];
}

- (void)logStructureCounts;
{
    NSArray *keys;
    int count, index;
    NSString *key;

    NSLog(@"----------------------------------------");
    keys = [[anonymousStructureCountsByType allKeys] sortedArrayUsingSelector:@selector(compare:)];
    count = [keys count];
    NSLog(@"%s, count: %d", _cmd, count);
    for (index = 0; index < count; index++) {
        key = [keys objectAtIndex:index];
        NSLog(@"%3d: %@ => %@", index, key, [anonymousStructureCountsByType objectForKey:key]);
    }
}

- (void)logReplacementTypes;
{
    NSArray *keys;
    int count, index;
    NSString *key;

    NSLog(@"----------------------------------------");
    keys = [[replacementTypes allKeys] sortedArrayUsingSelector:@selector(compare:)];
    count = [keys count];
    NSLog(@"%s, count: %d", _cmd, count);
    for (index = 0; index < count; index++) {
        key = [keys objectAtIndex:index];
        NSLog(@"%3d: %@ => %@", index, key, [[replacementTypes objectForKey:key] typeString]);
    }
}

- (void)logNamedStructures;
{
    NSArray *keys;
    NSString *key;
    int count, index;

    NSLog(@"----------------------------------------");
    keys = [[structuresByName allKeys] sortedArrayUsingSelector:@selector(compare:)];
    count = [keys count];
    NSLog(@"%s, count: %d", _cmd, count);
    for (index = 0; index < count; index++) {
        key = [keys objectAtIndex:index];
        NSLog(@"%2d: %@ => %@", index, key, [[structuresByName objectForKey:key] typeString]);
    }
}

- (void)logAnonymousStructures;
{
    NSArray *keys;
    NSString *key;
    int count, index;

    NSLog(@"----------------------------------------");
    keys = [[anonymousStructureNamesByType allKeys] sortedArrayUsingSelector:@selector(compare:)];
    count = [keys count];
    NSLog(@"%s, count: %d", _cmd, count);
    for (index = 0; index < count; index++) {
        key = [keys objectAtIndex:index];
        NSLog(@"%2d: %@ => %@", index, [anonymousStructureNamesByType objectForKey:key], key);
    }
}

- (void)logForcedTypedefs;
{
    NSLog(@"----------------------------------------");
    NSLog(@"%s, count: %d", _cmd, [forcedTypedefs count]);
    NSLog(@"forcedTypedefs: %@", [forcedTypedefs description]);
}

// Some anonymous structs don't have member names, but others do.
// Here we find the structs with member names and check to see if
// there's an identical struct without names.  If there's only one
// we'll make the one without names use the one with names.  If
// there's more, though, we don't try to guess which it should be.

- (void)processIsomorphicStructures;
{
    NSMutableDictionary *anonymousRemapping;
    NSMutableSet *duplicateMappings;
    NSArray *keys;
    int count, index;
    NSString *key;

    NSLog(@"----------------------------------------");
    anonymousRemapping = [[NSMutableDictionary alloc] init];
    duplicateMappings = [NSMutableSet set];

    keys = [[anonymousStructuresByType allKeys] sortedArrayUsingSelector:@selector(compare:)];
    count = [keys count];
    NSLog(@"%s, count: %d", _cmd, count);
    for (index = 0; index < count; index++) {
        CDType *structType;
        NSString *bareTypeString;

        key = [keys objectAtIndex:index];
        structType = [anonymousStructuresByType objectForKey:key];
        bareTypeString = [structType bareTypeString];
        if ([key isEqual:bareTypeString] == NO) {
            if ([duplicateMappings containsObject:bareTypeString] == NO && [anonymousStructuresByType objectForKey:bareTypeString] != nil) {
                NSString *existingValue;

                existingValue = [anonymousRemapping objectForKey:bareTypeString];
                if (existingValue == nil) {
                    [anonymousRemapping setObject:key forKey:bareTypeString];
                } else {
                    [duplicateMappings addObject:bareTypeString];
                    [anonymousRemapping removeObjectForKey:bareTypeString];
                }
            }
        }
    }

    // Now we need to combine anything that gets remapped.
    {
        NSArray *mapKeys;
        NSString *originalType, *replacementType;

        mapKeys = [anonymousRemapping allKeys];
        count = [mapKeys count];
        for (index = 0; index < count; index++) {
            int newCount;

            originalType = [mapKeys objectAtIndex:index];
            replacementType = [anonymousRemapping objectForKey:originalType];
            newCount = [[anonymousStructureCountsByType objectForKey:originalType] intValue] + [[anonymousStructureCountsByType objectForKey:replacementType] intValue];

            NSLog(@"Combining %@ with %@", originalType, replacementType);
            [anonymousStructureCountsByType setObject:[NSNumber numberWithInt:newCount] forKey:replacementType];
            [anonymousStructureCountsByType removeObjectForKey:originalType];
            [anonymousStructuresByType removeObjectForKey:originalType];

            [self replaceTypeString:originalType withTypeString:replacementType];
        }
    }

    [anonymousRemapping release];
}

- (void)replaceTypeString:(NSString *)originalTypeString withTypeString:(NSString *)replacementTypeString;
{
    CDTypeParser *aTypeParser;
    CDType *replacementType;

    aTypeParser = [[CDTypeParser alloc] initWithType:replacementTypeString];
    replacementType = [aTypeParser parseType];
    if (replacementType != nil)
        [replacementTypes setObject:replacementType forKey:originalTypeString];

    [aTypeParser release];
}

// Need to name anonymous structs if:
//   - used more than once
//   - OR used in a method
- (void)generateNamesForAnonymousStructures;
{
    int nameIndex = 1;
    NSArray *keys;
    int count, index;
    NSString *key;

    keys = [anonymousStructuresByType allKeys];
    count = [keys count];
    for (index = 0; index < count; index++) {
        key = [keys objectAtIndex:index];
        if ([[anonymousStructureCountsByType objectForKey:key] intValue] > 0
            || [forcedTypedefs containsObject:key] == YES) {
            [anonymousStructureNamesByType setObject:[NSString stringWithFormat:@"%@%d", anonymousBaseName, nameIndex++] forKey:key];
        }
    }
}

// TODO (2003-12-23): Add option to show/hide this section
// TODO (2003-12-23): auto-name unnamed members
// TODO (2003-12-23): sort by name or by dependency
// TODO (2003-12-23): declare in modules where they were first used

- (void)appendNamedStructuresToString:(NSMutableString *)resultString formatter:(CDTypeFormatter *)aTypeFormatter;
{
    NSArray *keys;
    NSString *key;
    int count, index;
    NSString *formattedString;
    CDType *type;

    keys = [[structuresByName allKeys] sortedArrayUsingSelector:@selector(compare:)];
    count = [keys count];

    for (index = 0; index < count; index++) {
        key = [keys objectAtIndex:index];
        type = [structuresByName objectForKey:key];
        formattedString = [aTypeFormatter formatVariable:nil type:[type typeString]];
        if (formattedString != nil) {
            [resultString appendString:formattedString];
            [resultString appendString:@";\n\n"];
        }
    }
}

- (void)appendTypedefsToString:(NSMutableString *)resultString formatter:(CDTypeFormatter *)aTypeFormatter;
{
    NSArray *keys;
    int count, index;
    NSString *typeString, *formattedString, *name;

    //keys = [[anonymousStructureNamesByType allKeys] sortedArrayUsingSelector:@selector(compare:)];
    keys = [anonymousStructureNamesByType allKeys];
    count = [keys count];

    for (index = 0; index < count; index++) {
        typeString = [keys objectAtIndex:index];

        name = [anonymousStructureNamesByType objectForKey:typeString];
        formattedString = [aTypeFormatter formatVariable:nil type:typeString];
        if (formattedString != nil) {
            [resultString appendString:@"typedef "];
            [resultString appendString:formattedString];
            [resultString appendFormat:@" %@;\n\n", name];
        }
    }
}

- (void)forceTypedefForStructure:(NSString *)typeString;
{
    [forcedTypedefs addObject:typeString];
}

- (CDType *)replacementForType:(CDType *)aType;
{
    return [replacementTypes objectForKey:[aType typeString]];
}

- (NSString *)typedefNameForStructureType:(CDType *)aType;
{
    NSString *result;

    result = [anonymousStructureNamesByType objectForKey:[aType typeString]];
    if (flags.shouldDebug == YES) {
        NSLog(@"[%p] %s, %@ -> %@", self, _cmd, [aType typeString], result);
    }

    return result;
}

- (void)registerStructure:(CDType *)structType name:(NSString *)aName withObject:(id <CDStructRegistration>)anObject
             usedInMethod:(BOOL)isUsedInMethod;
{
    NSNumber *oldCount;
    NSString *typeString;

    typeString = [structType typeString];

    if (isUsedInMethod == YES)
        [self forceTypedefForStructure:[structType typeString]];

    // Handle named structs
    // We don't count them because they'll always be declared at the top.
    if (aName != nil && [aName isEqual:@"?"] == NO) {
        CDType *existingType;

        existingType = [structuresByName objectForKey:aName];
        if (existingType == nil) {
            [structType registerMemberStructuresWithObject:anObject usedInMethod:NO];
            [structuresByName setObject:structType forKey:aName];
        } else if ([structType isEqual:existingType] == NO) {
            NSString *before;

            [structType registerMemberStructuresWithObject:anObject usedInMethod:NO];
            before = [existingType typeString];
            [existingType mergeWithType:structType];
            if ([before isEqual:[existingType typeString]] == NO) {
                NSLog(@"Merging %@ with %@", before, [structType typeString]);
                NSLog(@"Merged result: %@", [existingType typeString]);
            } else {
                //NSLog(@"No change from merging types.");
            }
        }
    }

    // Handle anonymous structs
    if (aName == nil || [aName isEqual:@"?"] == YES) {
        CDType *previousType;

        previousType = [anonymousStructuresByType objectForKey:typeString];
        if (previousType == nil) {
            [anonymousStructuresByType setObject:structType forKey:typeString];
            [structType registerMemberStructuresWithObject:anObject usedInMethod:NO];
        } else {
            //NSLog(@"Already registered this anonymous struct, previous: %@, current: %@", [previousType typeString], typeString);

            // Just count anonymous structs
            oldCount = [anonymousStructureCountsByType objectForKey:typeString];
            if (oldCount == nil)
                [anonymousStructureCountsByType setObject:[NSNumber numberWithInt:1] forKey:typeString];
            else
                [anonymousStructureCountsByType setObject:[NSNumber numberWithInt:[oldCount intValue] + 1] forKey:typeString];
        }
    }
}

@end
