//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import "CDStructureTable.h"

#import "rcsid.h"
#import <Foundation/Foundation.h>
#import "NSArray-Extensions.h"
#import "CDType.h"
#import "CDTypeFormatter.h"
#import "CDTypeName.h"
#import "CDTypeParser.h"

RCS_ID("$Header: /Volumes/Data/tmp/Tools/class-dump/CDStructureTable.m,v 1.14 2004/01/29 07:28:57 nygard Exp $");

@implementation CDStructureTable

- (id)init;
{
    if ([super init] == nil)
        return nil;

    structuresByName = [[NSMutableDictionary alloc] init];

    anonymousStructureCountsByType = [[NSMutableDictionary alloc] init];
    anonymousStructuresByType = [[NSMutableDictionary alloc] init];
    anonymousStructureNamesByType = [[NSMutableDictionary alloc] init];

    forcedTypedefs = [[NSMutableSet alloc] init];

    anonymousBaseName = nil;
    structureSignatures = [[NSMutableSet alloc] init];
    structureTypes = [[NSMutableArray alloc] init];
    replacementSignatures = [[NSMutableDictionary alloc] init];

    return self;
}

- (void)dealloc;
{
    [structuresByName release];

    [anonymousStructureCountsByType release];
    [anonymousStructuresByType release];
    [anonymousStructureNamesByType release];

    [forcedTypedefs release];
    [anonymousBaseName release];
    [structureSignatures release];
    [structureTypes release];
    [replacementSignatures release];

    [super dealloc];
}

- (NSString *)name;
{
    return name;
}

- (void)setName:(NSString *)newName;
{
    if (newName == name)
        return;

    [name release];
    name = [newName retain];
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

- (void)logPhase1Data;
{
    NSLog(@"[%p](%@)  > %s ----------------------------------------", self, name, _cmd);
    NSLog(@"structureSignatures: %@", [structureSignatures description]);
}

// Some anonymous structs don't have member names, but others do.
// Here we find the structs with member names and check to see if
// there's an identical struct without names.  If there's only one
// we'll make the one without names use the one with names.  If
// there's more, though, we don't try to guess which it should be.

- (void)finishPhase1;
{
    int count, index;
    CDType *aType;
    NSMutableSet *ambiguousSignatures;

    //NSLog(@"[%p](%@)  > %s ----------------------------------------", self, name, _cmd);
    ambiguousSignatures = [[NSMutableSet alloc] init];

    count = [structureTypes count];
    for (index = 0; index < count; index++) {
        NSString *keySignature, *bareSignature;

        aType = [structureTypes objectAtIndex:index];
        keySignature = [aType keyTypeString];
        bareSignature = [aType bareTypeString];
        if ([keySignature isEqual:bareSignature] == NO && [ambiguousSignatures containsObject:bareSignature] == NO) {
            //NSLog(@"%d: %@ != %@", index, keySignature, bareSignature);
            if ([replacementSignatures objectForKey:bareSignature] == nil) {
                [replacementSignatures setObject:keySignature forKey:bareSignature];
            } else {
                [replacementSignatures removeObjectForKey:bareSignature];
                [ambiguousSignatures addObject:bareSignature];
            }
        }
    }

    //NSLog(@"replacementSignatures: %@", [replacementSignatures description]);
    //NSLog(@"ambiguousSignatures: %@", [ambiguousSignatures description]);

    [ambiguousSignatures release];
}

- (void)logInfo;
{
    int count, index;
    NSArray *keys;
    NSString *key;

    NSLog(@"[%p](%@)  > %s ----------------------------------------", self, name, _cmd);
    keys = [structuresByName allKeys];
    count = [keys count];
    NSLog(@"%d named:", count);
    for (index = 0; index < count; index++) {
        key = [keys objectAtIndex:index];
        NSLog(@"%d: %@ => %@", index, key, [[structuresByName objectForKey:key] typeString]);
    }

    keys = [anonymousStructuresByType allKeys];
    count = [keys count];
    NSLog(@"%d anonymous:", count);
    for (index = 0; index < count; index++) {
        key = [keys objectAtIndex:index];
        NSLog(@"%d: %@ -> %@", index, key, [anonymousStructureCountsByType objectForKey:key]);
    }

    NSLog(@"[%p](%@) <  %s ----------------------------------------", self, name, _cmd);
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
        if ([[anonymousStructureCountsByType objectForKey:key] intValue] > 1
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
    NSString *key, *typeString, *formattedString, *aName;

    //keys = [[anonymousStructureNamesByType allKeys] sortedArrayUsingSelector:@selector(compare:)];
    keys = [anonymousStructureNamesByType allKeys];
    count = [keys count];

    for (index = 0; index < count; index++) {
        key = [keys objectAtIndex:index];
        typeString = [[anonymousStructuresByType objectForKey:key] typeString];

        aName = [anonymousStructureNamesByType objectForKey:key];
        formattedString = [aTypeFormatter formatVariable:nil type:typeString];
        if (formattedString != nil) {
            [resultString appendString:@"typedef "];
            [resultString appendString:formattedString];
            [resultString appendFormat:@" %@;\n\n", aName];
        }
    }
}

- (void)forceTypedefForStructure:(NSString *)typeString;
{
    [forcedTypedefs addObject:typeString];
}

- (CDType *)replacementForType:(CDType *)aType;
{
    return [anonymousStructuresByType objectForKey:[replacementSignatures objectForKey:[aType keyTypeString]]];
}

- (NSString *)typedefNameForStructureType:(CDType *)aType;
{
    NSString *result;

    result = [anonymousStructureNamesByType objectForKey:[aType keyTypeString]];
    if (flags.shouldDebug == YES) {
        NSLog(@"[%p] %s, %@ -> %@", self, _cmd, [aType keyTypeString], result);
    }

    return result;
}

// Out of phase one we want any mappings we need, and maybe to know which anonymous structs map ambiguously.
- (void)phase1RegisterStructure:(CDType *)aStructure;
{
    NSString *aName;

    //NSLog(@" > %s", _cmd);
    //NSLog(@"keySignature: %@ (%d)", [aStructure keyTypeString], [structureSignatures containsObject:[aStructure keyTypeString]]);

    aName = [[aStructure typeName] description];
    if (aName == nil || [aName isEqual:@"?"] == YES) {
        if ([structureSignatures containsObject:[aStructure keyTypeString]] == NO) {
            [structureSignatures addObject:[aStructure keyTypeString]];
            [structureTypes addObject:aStructure];
        }
    }

    //NSLog(@"<  %s", _cmd);
}

// Returns YES to indicate that we should count references for children.
- (BOOL)phase2RegisterStructure:(CDType *)aStructure withObject:(id <CDStructureRegistration>)anObject usedInMethod:(BOOL)isUsedInMethod
                countReferences:(BOOL)shouldCountReferences;
{
    BOOL shouldCountMembers = NO;
    NSString *aName;
    NSString *keySignature;

    //NSLog(@"[%p](%@)  > %s", self, name, _cmd);
    //NSLog(@"aStructure: %p", aStructure);

    aName = [[aStructure typeName] description];
    keySignature = [aStructure keyTypeString];

    if (isUsedInMethod == YES)
        [self forceTypedefForStructure:keySignature];

    // Handle anonymous structs
    if (aName == nil || [aName isEqual:@"?"] == YES) {
        CDType *previousType;
        NSString *remappedSignature;
        NSString *old;

        // ((Remapped - just add reference to original (but it may not exist yet) ))
        // Exists already - add reference
        // new - add reference, recursively count references

        old = keySignature;
        remappedSignature = [replacementSignatures objectForKey:keySignature];
        if (remappedSignature != nil) {
            // There may not be an object for the replaced type yet.
            keySignature = remappedSignature;
        }

        //NSLog(@"%s, remappedSignature: %@, aStructure: %@", _cmd, old, [aStructure keyTypeString]);

        previousType = [anonymousStructuresByType objectForKey:keySignature];
        if (previousType == nil) {
            [anonymousStructuresByType setObject:aStructure forKey:keySignature];
            [anonymousStructureCountsByType setObject:[NSNumber numberWithInt:1] forKey:keySignature];
            shouldCountMembers = YES;
        } else {
            //NSLog(@"Already registered this anonymous struct, previous: %@, current: %@", [previousType typeString], typeString);

            [previousType mergeWithType:aStructure];

            if (shouldCountReferences == YES) {
                NSNumber *oldCount;

                // Just count anonymous structs
                oldCount = [anonymousStructureCountsByType objectForKey:keySignature];
                if (oldCount == nil) {
                    NSLog(@"Warning: This should already have a count.");
                    [anonymousStructureCountsByType setObject:[NSNumber numberWithInt:1] forKey:keySignature];
                } else
                    [anonymousStructureCountsByType setObject:[NSNumber numberWithInt:[oldCount intValue] + 1] forKey:keySignature];
            }
        }
    } else {
        // Handle named structs
        // We don't count them because they'll always be declared at the top.

        CDType *existingType;

        existingType = [structuresByName objectForKey:aName];
        //NSLog(@"Named structure: %@ %@, existingType: %@", aName, [aStructure typeString], [existingType typeString]);
        //NSLog(@"keySignature: %@", keySignature);
        if (existingType == nil) {
            [structuresByName setObject:aStructure forKey:aName];
            shouldCountMembers = YES;
        } else /*if ([[aStructure typeString] isEqual:keySignature] == NO)*/ {
            NSString *before;

            before = [existingType keyTypeString];
            [existingType mergeWithType:aStructure];
            if ([self shouldDebug] == YES) {
                if ([before isEqual:[existingType keyTypeString]] == NO) {
                    NSLog(@"Merging %@ with %@", before, [aStructure keyTypeString]);
                    NSLog(@"Merged result: %@", [existingType keyTypeString]);
                } else {
                    //NSLog(@"No change from merging types.");
                }
            }
        }
    }

    // We always register recursively (so that we can merge member names if necessary) but we don't always add references?

    //NSLog(@"[%p](%@) <  %s", self, name, _cmd);
    return shouldCountMembers;
}

- (void)generateMemberNames;
{
    [[structuresByName allValues] makeObjectsPerformSelector:@selector(generateMemberNames)];
    [[anonymousStructuresByType allValues] makeObjectsPerformSelector:@selector(generateMemberNames)];
}

@end
