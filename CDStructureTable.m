// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import "CDStructureTable.h"

#import "NSArray-Extensions.h"
#import "CDClassDump.h"
#import "CDSymbolReferences.h"
#import "CDType.h"
#import "CDTypeController.h"
#import "CDTypeFormatter.h"
#import "CDTypeName.h"
#import "CDTypeParser.h"
#import "NSError-CDExtensions.h"
#import "CDStructureInfo.h"

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

// In a marvel of efficiency, it looks like we parse every type _three_ times!

// Phase 0: Try sorting by structure nesting level

// - need to find structure member names.
// - Types used in methods need to be declared at the top level.


// Step 1: Just gather top level counts by unmodified type string.

//static BOOL debug = YES;

@implementation CDStructureTable

- (id)init;
{
    if ([super init] == nil)
        return nil;

    identifier = nil;
    anonymousBaseName = nil;

    phase0_ivar_structureInfo = [[NSMutableDictionary alloc] init];
    phase0_method_structureInfo = [[NSMutableDictionary alloc] init];

    flags.shouldDebug = NO;

    return self;
}

- (void)dealloc;
{
    [identifier release];
    [anonymousBaseName release];

    [phase0_ivar_structureInfo release];
    [phase0_method_structureInfo release];

    [super dealloc];
}

- (NSString *)identifier;
{
    return identifier;
}

- (void)setIdentifier:(NSString *)newIdentifier;
{
    if (newIdentifier == identifier)
        return;

    [identifier release];
    identifier = [newIdentifier retain];
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

// Need to name anonymous structs if:
//   - used more than once
//   - OR used in a method
- (void)generateNamesForAnonymousStructures;
{
}

// TODO (2003-12-23): Add option to show/hide this section
// TODO (2003-12-23): sort by name or by dependency
// TODO (2003-12-23): declare in modules where they were first used

- (void)appendNamedStructuresToString:(NSMutableString *)resultString
                            formatter:(CDTypeFormatter *)aTypeFormatter
                     symbolReferences:(CDSymbolReferences *)symbolReferences;
{
#if 0
#if 0
    for (NSString *key in [[structuresByName allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        CDType *type;

        type = [structuresByName objectForKey:key];
#endif
        for (CDType *type in foo) {

        if ([[aTypeFormatter typeController] shouldShowName:[[type typeName] description]]) {
            NSString *formattedString;

            formattedString = [aTypeFormatter formatVariable:nil type:[type typeString] symbolReferences:symbolReferences];
            if (formattedString != nil) {
                [resultString appendString:formattedString];
                [resultString appendString:@";\n\n"];
            }
        }
    }
#endif
}

- (void)appendTypedefsToString:(NSMutableString *)resultString
                     formatter:(CDTypeFormatter *)aTypeFormatter
              symbolReferences:(CDSymbolReferences *)symbolReferences;
{
#if 0
    // TODO (2009-07-27): Why aren't these sorted?
    for (NSString *key in [anonymousStructureNamesByType allKeys]) {
        NSString *name;

        name = [anonymousStructureNamesByType objectForKey:key];

        if ([[aTypeFormatter typeController] shouldShowName:name]) {
            NSString *typeString, *formattedString;

            typeString = [[anonymousStructuresByType objectForKey:key] typeString];
            formattedString = [aTypeFormatter formatVariable:nil type:typeString symbolReferences:symbolReferences];
            if (formattedString != nil) {
                [resultString appendFormat:@"typedef %@ %@;\n\n", formattedString, name];
            }
        }
    }
#endif
}

- (CDType *)replacementForType:(CDType *)aType;
{
    return nil;
    //return [anonymousStructuresByType objectForKey:[replacementSignatures objectForKey:[aType keyTypeString]]];
}

- (NSString *)typedefNameForStructureType:(CDType *)aType;
{
    return nil;
}

// Now I just want a list of the named structures
- (void)phase0RegisterStructure:(CDType *)aStructure ivar:(BOOL)isIvar;
{
    NSMutableDictionary *dict;
    NSString *key;
    CDStructureInfo *info;

    // Find exceptions first, then merge non-exceptions.

    if (isIvar)
        dict = phase0_ivar_structureInfo;
    else
        dict = phase0_method_structureInfo;

    key = [aStructure typeString];
    info = [dict objectForKey:key];
    if (info == nil) {
        info = [[CDStructureInfo alloc] initWithTypeString:[aStructure typeString]];
        [dict setObject:info forKey:key];
        [info release];
    } else {
        [info addReferenceCount:1];
    }
}

- (void)finishPhase0;
{
    NSMutableArray *all;
    NSMutableDictionary *nameDict, *nameDict2;
    NSMutableDictionary *anonDict, *anonDict2;

    nameDict = [NSMutableDictionary dictionary];
    anonDict = [NSMutableDictionary dictionary];
    all = [NSMutableArray array];
    [all addObjectsFromArray:[phase0_ivar_structureInfo allValues]];
    [all addObjectsFromArray:[phase0_method_structureInfo allValues]];

    for (CDStructureInfo *info in all) {
        NSString *name;
        NSMutableArray *group;

        name = [[[info type] typeName] description];

        if ([@"?" isEqualToString:name]) {
            NSString *key;

            key = [[info type] reallyBareTypeString];
            group = [anonDict objectForKey:key];
            if (group == nil) {
                group = [[NSMutableArray alloc] init];
                [group addObject:info];
                [anonDict setObject:group forKey:key];
                [group release];
            } else {
                [group addObject:info];
            }
        } else {
            group = [nameDict objectForKey:name];
            if (group == nil) {
                group = [[NSMutableArray alloc] init];
                [group addObject:info];
                [nameDict setObject:group forKey:name];
                [group release];
            } else {
                [group addObject:info];
            }
        }
    }


    // Now... for each group, make sure we can combine them all together.
    // If not, this means that either the types or the member names conflicted, and we save the entire group as an exception.
    nameDict2 = [NSMutableDictionary dictionary];
    for (NSString *key in [nameDict allKeys]) {
        NSMutableArray *group;
        CDStructureInfo *combined = nil;
        BOOL canBeCombined = YES;

        //NSLog(@"key... %@", key);
        group = [nameDict objectForKey:key];
        for (CDStructureInfo *info in group) {
            if (combined == nil) {
                combined = [info copy];
            } else {
                if ([[combined type] canMergeWithType:[info type]]) {
                    [[combined type] mergeWithType:[info type]];
                    [combined addReferenceCount:[info referenceCount]];
                } else {
                    canBeCombined = NO;
                    break;
                }
            }
        }

        if (canBeCombined) {
            [nameDict2 setObject:combined forKey:key];
        } else {
            NSLog(@"Can't be combined: %@", key);
            NSLog(@"group: %@", group);
        }

        [combined release];
    }

    NSLog(@"======================================================================");
    anonDict2 = [NSMutableDictionary dictionary];
    for (NSString *key in [anonDict allKeys]) {
        NSMutableArray *group;
        CDStructureInfo *combined = nil;
        BOOL canBeCombined = YES;

        NSLog(@"key... %@", key);
        group = [anonDict objectForKey:key];
        for (CDStructureInfo *info in group) {
            if (combined == nil) {
                combined = [info copy];
            } else {
                if ([[combined type] canMergeWithType:[info type]]) {
                    [[combined type] mergeWithType:[info type]];
                    [combined addReferenceCount:[info referenceCount]];
                } else {
                    NSLog(@"previous: %@", [[combined type] typeString]);
                    NSLog(@"    This: %@", [[info type] typeString]);
                    canBeCombined = NO;
                    break;
                }
            }
        }

        if (canBeCombined) {
            [anonDict2 setObject:combined forKey:key];
        } else {
            NSLog(@"Can't be combined: %@", key);
            NSLog(@"group: %@", group);
        }

        [combined release];
    }

    for (NSString *key in nameDict2) {
        NSLog(@"%@ = %@", key, [nameDict2 objectForKey:key]);
    }

    // Reset all counts to be 2.  These are all top level structures, and must be shown at the top.
    // Next: For each of these types, recursively add one reference to each substructure.
    // Then: Any type with >1 reference needs to be shown at the top.  Any with 1 ref don't.

    for (NSString *key in [[anonDict allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        NSMutableArray *group = [anonDict objectForKey:key];
        if ([group count] > 1)
            NSLog(@"group: %@, %@", key, group);
    }
#if 0
    NSLog(@" > %s", _cmd);
    NSLog(@"ivar:");
    for (CDStructureInfo *info in [[phase0_ivar_structureInfo allValues] sortedArrayUsingSelector:@selector(ascendingCompareByStructureDepth:)]) {
        NSLog(@"%@", [info shortDescription]);
    }
    NSLog(@"----------------------------------------");
    NSLog(@"method:");
    for (CDStructureInfo *info in [[phase0_method_structureInfo allValues] sortedArrayUsingSelector:@selector(ascendingCompareByStructureDepth:)]) {
        NSLog(@"%@", [info shortDescription]);
    }
    NSLog(@"<  %s", _cmd);
#endif
    exit(99);
}

- (void)generateMemberNames;
{
}

- (void)phase1WithTypeController:(CDTypeController *)typeController;
{
}

- (void)phase1RegisterStructure:(CDType *)aStructure;
{
}

- (void)finishPhase1;
{
}

- (void)mergePhase1StructuresAtDepth:(NSUInteger)depth;
{
}

- (void)logPhase2Info;
{
}

@end
