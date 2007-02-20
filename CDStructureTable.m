//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2006  Steve Nygard

#import "CDStructureTable.h"

#import <Foundation/Foundation.h>
#import "NSArray-Extensions.h"
#import "CDClassDump.h"
#import "CDSymbolReferences.h"
#import "CDType.h"
#import "CDTypeFormatter.h"
#import "CDTypeName.h"
#import "CDTypeParser.h"

// Phase 1, registration: Only looks at anonymous (no name, or name is "?") structures
// Phase 1, finish: - sets up replacementSignatures
// Phase 1, results: - replacementSignatures used in phase 2, remapping of some sort
//                   - replacementSignatures used in -replacementForType:
//
// The goal of phase 1 is to build a mapping of annonymous structures that don't have member names, to unambiguous keyTypeStrings that do have member names.
// For example, if we have a union (?="thin"[128c]"fat"[128S]), this generates this mapping:
//     (?=[128c][128S]) = (?="thin"[128c]"fat"[128S])
// So if we find unions like this (?=[128c][128S]), we can replace it with one that has member names.
// On the other hand, if we have two unions that have different member names but have the same structure, we can't unambigously map from the bareTypeString to one with member names.
// For example, (?="thin"[128c]"fat"[128S]) and (?="foo"[128c]"bar"[128S]) both have (?=[128c][128S]) as the bareTypeString.



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
    replacementSignatures = [[NSMutableDictionary alloc] init];
    keyTypeStringsByBareTypeStrings = [[NSMutableDictionary alloc] init];

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
    [replacementSignatures release];
    [keyTypeStringsByBareTypeStrings release];

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
    NSLog(@"keyTypeStringsByBareTypeStrings:\n%@", keyTypeStringsByBareTypeStrings);
}

// Some anonymous structs don't have member names, but others do.
// Here we find the structs with member names and check to see if
// there's an identical struct without names.  If there's only one
// we'll make the one without names use the one with names.  If
// there's more, though, we don't try to guess which it should be.

- (void)finishPhase1;
{
    NSArray *keys;
    unsigned int count, index;

    //NSLog(@"[%p](%@)  > %s ----------------------------------------", self, name, _cmd);
    keys = [keyTypeStringsByBareTypeStrings allKeys];
    count = [keys count];
    for (index = 0; index < count; index++) {
        NSString *key;
        NSMutableSet *value;

        key = [keys objectAtIndex:index];
        value = [keyTypeStringsByBareTypeStrings objectForKey:key];
        [value removeObject:key]; // Remove the bare string.  This should leave only ones with member names.
        // If there's more than one, it means they have different member names.
        if ([value count] == 1) {
            [replacementSignatures setObject:[value anyObject] forKey:key];
        } else if ([value count] == 2) {
            if (flags.shouldDebug)
                NSLog(@"%s, %@ -> (%u) %@", _cmd, key, [value count], value);
        }
    }
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
// TODO (2003-12-23): sort by name or by dependency
// TODO (2003-12-23): declare in modules where they were first used

- (void)appendNamedStructuresToString:(NSMutableString *)resultString classDump:(CDClassDump *)aClassDump formatter:(CDTypeFormatter *)aTypeFormatter symbolReferences:(CDSymbolReferences *)symbolReferences;
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

        if ([aClassDump shouldMatchRegex] == YES && [aClassDump regexMatchesString:[[type typeName] description]] == NO)
            continue;

        formattedString = [aTypeFormatter formatVariable:nil type:[type typeString] symbolReferences:symbolReferences];
        if (formattedString != nil) {
            [resultString appendString:formattedString];
            [resultString appendString:@";\n\n"];
        }
    }
}

- (void)appendTypedefsToString:(NSMutableString *)resultString classDump:(CDClassDump *)aClassDump formatter:(CDTypeFormatter *)aTypeFormatter symbolReferences:(CDSymbolReferences *)symbolReferences;
{
    NSArray *keys;
    int count, index;
    NSString *key, *typeString, *formattedString, *aName;

    //keys = [[anonymousStructureNamesByType allKeys] sortedArrayUsingSelector:@selector(compare:)];
    keys = [anonymousStructureNamesByType allKeys];
    count = [keys count];

    for (index = 0; index < count; index++) {
        key = [keys objectAtIndex:index];
        aName = [anonymousStructureNamesByType objectForKey:key];

        if ([aClassDump shouldMatchRegex] == YES && [aClassDump regexMatchesString:aName] == NO)
            continue;

        typeString = [[anonymousStructuresByType objectForKey:key] typeString];

        formattedString = [aTypeFormatter formatVariable:nil type:typeString symbolReferences:symbolReferences];
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
    //NSLog(@"keySignature: %@", [aStructure keyTypeString]);

    aName = [[aStructure typeName] description];
    if (aName == nil || [aName isEqual:@"?"] == YES) {
        NSString *bareStr, *keyStr;
        NSMutableSet *values;

        bareStr = [aStructure bareTypeString]; // No member names at all
        keyStr = [aStructure keyTypeString]; // Only top level member names
        values = [keyTypeStringsByBareTypeStrings objectForKey:bareStr];
        if (values == nil) {
            values = [[NSMutableSet alloc] init];
            [keyTypeStringsByBareTypeStrings setObject:values forKey:bareStr];
            [values release];
        }
        [values addObject:keyStr];
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
