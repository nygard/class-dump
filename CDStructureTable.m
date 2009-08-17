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

static BOOL debug = YES;

@implementation CDStructureTable

- (id)init;
{
    if ([super init] == nil)
        return nil;

    identifier = nil;
    anonymousBaseName = nil;

    phase0_structureInfo = [[NSMutableDictionary alloc] init];

    phase1_structureInfo = [[NSMutableDictionary alloc] init];
    phase1_maxDepth = 0;
    phase1_groupedByDepth = [[NSMutableDictionary alloc] init];

    phase2_namedStructureInfo = [[NSMutableDictionary alloc] init];
    phase2_anonStructureInfo = [[NSMutableDictionary alloc] init];
    phase2_nameExceptions = [[NSMutableArray alloc] init];
    phase2_anonExceptions = [[NSMutableArray alloc] init];

    flags.shouldDebug = NO;

    return self;
}

- (void)dealloc;
{
    [identifier release];
    [anonymousBaseName release];

    [phase0_structureInfo release];

    [phase1_structureInfo release];
    [phase1_groupedByDepth release];

    [phase2_namedStructureInfo release];
    [phase2_anonStructureInfo release];
    [phase2_nameExceptions release];
    [phase2_anonExceptions release];

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
#if 1
    for (NSString *key in [[phase2_namedStructureInfo allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        CDType *type;

        type = [(CDStructureInfo *)[phase2_namedStructureInfo objectForKey:key] type];
        if ([[aTypeFormatter typeController] shouldShowName:[[type typeName] description]]) {
            NSString *formattedString;

            formattedString = [aTypeFormatter formatVariable:nil parsedType:type symbolReferences:symbolReferences];
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
#if 1
    for (CDStructureInfo *info in [[phase2_anonStructureInfo allValues] sortedArrayUsingSelector:@selector(ascendingCompareByStructureDepth:)]) {
        NSString *formattedString;
        NSString *name = @"CDAnonStruct_";

        formattedString = [aTypeFormatter formatVariable:nil parsedType:[info type] symbolReferences:symbolReferences];
        if (formattedString != nil) {
            [resultString appendFormat:@"typedef %@ %@;\n\n", formattedString, name];
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
    NSString *key;
    CDStructureInfo *info;

    // Find exceptions first, then merge non-exceptions.

    key = [aStructure typeString];
    info = [phase0_structureInfo objectForKey:key];
    if (info == nil) {
        info = [[CDStructureInfo alloc] initWithTypeString:[aStructure typeString]];
        if (isIvar == NO)
            [info setIsUsedInMethod:YES];
        [phase0_structureInfo setObject:info forKey:key];
        [info release];
    } else {
        [info addReferenceCount:1];
        if (isIvar == NO)
            [info setIsUsedInMethod:YES];
    }
}

- (void)finishPhase0;
{
}

- (void)generateMemberNames;
{
}

- (void)phase1WithTypeController:(CDTypeController *)typeController;
{
    for (CDStructureInfo *info in [phase0_structureInfo allValues]) {
        [[info type] phase1RegisterStructuresWithObject:typeController];
    }
}

// Need to gather all of the structures, since some substructures may have member names we'd otherwise miss.
- (void)phase1RegisterStructure:(CDType *)aStructure;
{
    NSString *key;
    CDStructureInfo *info;

    key = [aStructure typeString];
    info = [phase1_structureInfo objectForKey:key];
    if (info == nil) {
        info = [[CDStructureInfo alloc] initWithTypeString:[aStructure typeString]];
        [phase1_structureInfo setObject:info forKey:key];
        [info release];
    } else {
        [info addReferenceCount:1];
    }
}

// Need to merge names bottom-up to catch cases like: {?=@@iiffff{_NSRect={_NSPoint=ff}{_NSSize=ff}}{?=b1b1b1b1b1b27}}

- (void)finishPhase1;
{
    NSLog(@"%s ======================================================================", _cmd);

    // The deepest union may not be at the top level (buried in a structure instead), so need to get the depth here.
    // But we'll take the max of structure and union depths in the CDTypeController anyway.

    for (CDStructureInfo *info in [phase1_structureInfo allValues]) {
        NSUInteger depth;

        depth = [[info type] structureDepth];
        if (phase1_maxDepth < depth)
            phase1_maxDepth = depth;
    }
    NSLog(@"[%@] Maximum structure depth is: %u", identifier, phase1_maxDepth);

    {
        for (CDStructureInfo *info in [phase1_structureInfo allValues]) {
            NSNumber *key;
            NSMutableArray *group;

            key = [NSNumber numberWithUnsignedInteger:[[info type] structureDepth]];
            group = [phase1_groupedByDepth objectForKey:key];
            if (group == nil) {
                group = [[NSMutableArray alloc] init];
                [group addObject:info];
                [phase1_groupedByDepth setObject:group forKey:key];
                [group release];
            } else {
                [group addObject:info];
            }
        }

        NSLog(@"depth groups: %@", [[phase1_groupedByDepth allKeys] sortedArrayUsingSelector:@selector(compare:)]);
    }
}

- (NSUInteger)phase1_maxDepth;
{
    return phase1_maxDepth;
}

// From lowest to highest depths:
// - Go through all infos at that level
//   - recursively (bottom up) try to merge substructures into that type, to get names/full types
// - merge all mergeable infos at that level

- (void)phase2AtDepth:(NSUInteger)depth typeController:(CDTypeController *)typeController;
{
    NSNumber *depthKey;
    NSArray *infos;
    NSMutableDictionary *nameDict, *anonDict;

    NSLog(@"[%@] %s, depth: %u", identifier, _cmd, depth);
    depthKey = [NSNumber numberWithUnsignedInt:depth];
    infos = [phase1_groupedByDepth objectForKey:depthKey];

    for (CDStructureInfo *info in infos) {
        // recursively (bottom up) try to merge substructures into that type, to get names/full types
        NSLog(@"----------------------------------------");
        NSLog(@"Trying phase2Merge with on %@", [[info type] typeString]);
        [[info type] phase2MergeWithTypeController:typeController];
    }

    // merge all mergeable infos at that level
    nameDict = [NSMutableDictionary dictionary];
    anonDict = [NSMutableDictionary dictionary];

    for (CDStructureInfo *info in infos) {
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
                //NSLog(@"old: %@", [[combined type] typeString]);
                //NSLog(@"new: %@", [[info type] typeString]);
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
            [phase2_namedStructureInfo setObject:combined forKey:key];
        } else {
            NSLog(@"Can't be combined: %@", key);
            NSLog(@"group: %@", group);
            [phase2_nameExceptions addObjectsFromArray:group];
        }

        [combined release];
    }

    NSLog(@"======================================================================");
    for (NSString *key in [anonDict allKeys]) {
        NSMutableArray *group;
        CDStructureInfo *combined = nil;
        BOOL canBeCombined = YES;

        //NSLog(@"key... %@", key);
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
            [phase2_anonStructureInfo setObject:combined forKey:key];
        } else {
            NSLog(@"Can't be combined: %@", key);
            NSLog(@"group: %@", group);
            [phase2_anonExceptions addObjectsFromArray:group];
        }

        [combined release];
    }
}

- (CDType *)phase2ReplacementForType:(CDType *)type;
{
    NSString *name;

    name = [[type typeName] description];
    if ([@"?" isEqualToString:name]) {
        return [(CDStructureInfo *)[phase2_anonStructureInfo objectForKey:[type reallyBareTypeString]] type];
    } else {
        return [(CDStructureInfo *)[phase2_namedStructureInfo objectForKey:name] type];
    }

    return nil;
}

- (void)mergePhase1StructuresAtDepth:(NSUInteger)depth;
{
}

- (void)logPhase2Info;
{
    NSLog(@" > %s", _cmd);
    NSLog(@"****************************************");
    NSLog(@"[%@] named:", identifier);
    for (CDStructureInfo *info in [[phase2_namedStructureInfo allValues] sortedArrayUsingSelector:@selector(ascendingCompareByStructureDepth:)]) {
        NSLog(@"%@", [info shortDescription]);
    }
    NSLog(@"****************************************");
    NSLog(@"[%@] anon:", identifier);
    for (CDStructureInfo *info in [[phase2_anonStructureInfo allValues] sortedArrayUsingSelector:@selector(ascendingCompareByStructureDepth:)]) {
        NSLog(@"%@", [info shortDescription]);
    }
    NSLog(@"<  %s", _cmd);
}

- (void)phase2ReplacementOnPhase0WithTypeController:(CDTypeController *)typeController;
{
    NSLog(@"[%@]  > %s", identifier, _cmd);

#if 0
    {
        CDStructureInfo *info = [phase2_namedStructureInfo objectForKey:@"_NSTypesetterGlyphInfo"];

        NSLog(@"info = %@", [info shortDescription]);
        NSLog(@"typeString: %@", [[info type] typeString]);
    }
#endif

    for (CDStructureInfo *info in [phase0_structureInfo allValues]) {
        NSString *before, *after;

        before = [[info type] typeString];
        [[info type] phase2MergeWithTypeController:typeController];
        after = [[info type] typeString];
        if (debug && [before isEqualToString:after] == NO) {
            NSLog(@"----------------------------------------");
            NSLog(@"%s, before != after", _cmd);
            NSLog(@"before: %@", before);
            NSLog(@" after: %@", after);
        }
    }

    NSLog(@"[%@] <  %s", identifier, _cmd);
}

@end
