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

static BOOL debug = YES;

@implementation CDStructureTable

- (id)init;
{
    if ([super init] == nil)
        return nil;

    identifier = nil;
    anonymousBaseName = nil;

    topLevelStructureInfo = [[NSMutableDictionary alloc] init];

    phase1NamedStructureInfo = [[NSMutableDictionary alloc] init];
    phase1AnonStructureInfo = [[NSMutableDictionary alloc] init];

    phase2NamedStructureInfo = [[NSMutableDictionary alloc] init];
    phase2AnonStructureInfo = [[NSMutableDictionary alloc] init];
    phase2NameExceptions = [[NSMutableDictionary alloc] init];
    phase2AnonExceptions = [[NSMutableDictionary alloc] init];

    flags.shouldDebug = NO;

    return self;
}

- (void)dealloc;
{
    [identifier release];
    [anonymousBaseName release];

    [topLevelStructureInfo release];

    [phase1NamedStructureInfo release];
    [phase1AnonStructureInfo release];
    [phase2NamedStructureInfo release];
    [phase2AnonStructureInfo release];
    [phase2NameExceptions release];
    [phase2AnonExceptions release];

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
- (void)phase0RegisterStructure:(CDType *)aStructure;
{
    CDStructureInfo *info;
    NSString *key;

    key = [aStructure typeString];
    info = [topLevelStructureInfo objectForKey:key];
    if (info == nil) {
        info = [[CDStructureInfo alloc] initWithTypeString:key];
        [topLevelStructureInfo setObject:info forKey:key];
        [info release];
    } else {
        [info addReferenceCount:1];
    }
}

// The top level structure of each name should have merged names.  Substructure members are unnamed.
- (void)finishPhase0;
{
#if 0
    NSLog(@" > %s", _cmd);
    //NSLog(@"topLevelStructureInfo: %@", topLevelStructureInfo);
    for (CDStructureInfo *info in [[topLevelStructureInfo allValues] sortedArrayUsingSelector:@selector(ascendingCompareByStructureDepth:)]) {
        NSLog(@"%@", [info shortDescription]);
    }
    NSLog(@"<  %s", _cmd);
#endif
}
#if 0
{
    NSMutableDictionary *dict1, *dict2;
    NSMutableSet *exceptionNames, *anonExceptionNames;
    NSMutableArray *exceptionTypes, *anonExceptionTypes;
    NSArray *strs;

    NSLog(@"======================================================================");

    dict1 = [NSMutableDictionary dictionary];
    anonExceptionNames = [NSMutableSet set];
    anonExceptionTypes = [NSMutableArray array];

    strs = [[unnamedStructureTypeStrings allObjects] sortedArrayUsingSelector:@selector(compare:)];
    for (NSString *str in strs) {
        CDTypeParser *parser;
        NSError *error;
        CDType *type;

        NSLog(@"unnamed struct type = %@", str);

        parser = [[CDTypeParser alloc] initWithType:str];
        type = [parser parseType:&error];
        if (type == nil) {
            NSLog(@"Warning: Parsing type in -finishPhase0 failed, %@, %@", str, [error myExplanation]);
        } else {
            NSString *key;

            key = [type bareTypeString];
            if ([anonExceptionNames containsObject:key]) {
                [anonExceptionTypes addObject:type];
            } else {
                CDType *previousType;

                previousType = [dict1 objectForKey:key];
                if (previousType == nil) {
                    [dict1 setObject:type forKey:key];
                } else {
                    NSLog(@"dupe anon types.");
                    if ([previousType canMergeTopLevelWithType:type]) {
                        // Well, merge them!  member names AND ID/Object types
                        [previousType mergeTopLevelWithType:type];
                    } else {
                        NSLog(@"Error: Can't merge types for name: %@", key);
                        NSLog(@"old: %@", [previousType typeString]);
                        NSLog(@"new: %@", [type typeString]);

                        [anonExceptionNames addObject:key];
                        [anonExceptionTypes addObject:previousType];
                        [anonExceptionTypes addObject:type];
                        [dict1 removeObjectForKey:key];
                    }
                }
            }
        }

        [parser release];
    }

    NSLog(@"****************************************");
    NSLog(@"****************************************");
    NSLog(@"%u anon exception names, with %u types", [anonExceptionNames count], [anonExceptionTypes count]);
    NSLog(@"****************************************");
    for (CDType *type in anonExceptionTypes) {
        NSLog(@"anon type: %u %@ %@", [type structureDepth], [type bareTypeString], [type typeString]);
    }
    NSLog(@"****************************************");

    for (NSString *key in [[dict1 allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        CDType *type = [dict1 objectForKey:key];

        NSLog(@"anon type: %u %@ %@", [type structureDepth], [type keyTypeString], [type typeString]);
    }
    NSLog(@"****************************************");
    NSLog(@"****************************************");


    dict2 = [NSMutableDictionary dictionary];
    exceptionNames = [NSMutableSet set];
    exceptionTypes = [NSMutableArray array];

    strs = [[namedStructureTypeStrings allObjects] sortedArrayUsingSelector:@selector(compare:)];
    //NSLog(@"named structs: %@", strs);

    for (NSString *str in strs) {
        CDTypeParser *parser;
        NSError *error;
        CDType *type;

        parser = [[CDTypeParser alloc] initWithType:str];
        type = [parser parseType:&error];
        if (type == nil) {
            NSLog(@"Warning: Parsing type in -finishPhase0 failed, %@, %@", str, [error myExplanation]);
        } else {
            NSString *key;

            //[foo addObject:type];

            key = [[type typeName] description];
            if ([exceptionNames containsObject:key]) {
                [exceptionTypes addObject:type];
            } else {
                CDType *previousType;

                previousType = [dict2 objectForKey:key];
                if (previousType == nil) {
                    [dict2 setObject:type forKey:key];
                } else {
                    if ([previousType canMergeTopLevelWithType:type]) {
                        // Well, merge them!  member names AND ID/Object types
                        [previousType mergeTopLevelWithType:type];
                    } else {
                        NSLog(@"Error: Can't merge types for name: %@", key);
                        NSLog(@"old: %@", [previousType typeString]);
                        NSLog(@"new: %@", [type typeString]);
                        // TODO: Build list of exceptions
                        [exceptionNames addObject:key];
                        [exceptionTypes addObject:previousType];
                        [exceptionTypes addObject:type];
                        [dict2 removeObjectForKey:key];
                    }
                }
            }
        }
        [parser release];
    }

#if 1
    for (NSString *key in [[dict2 allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        [foo addObject:[dict2 objectForKey:key]];
    }
#endif

    NSLog(@"%u exception names, with %u types", [exceptionNames count], [exceptionTypes count]);
}
#endif

- (void)generateMemberNames;
{
}

- (void)phase1WithTypeController:(CDTypeController *)typeController;
{
    for (CDStructureInfo *info in [topLevelStructureInfo allValues]) {
        [[info type] phase1RegisterStructuresWithObject:typeController];
    }
}

- (void)phase1RegisterStructure:(CDType *)aStructure;
{
    CDStructureInfo *info;
    NSString *key;

    if ([@"?" isEqualToString:[[aStructure typeName] description]]) {
        //key = [aStructure keyTypeString];
        key = [aStructure typeString];

        info = [phase1AnonStructureInfo objectForKey:key];
        if (info == nil) {
            info = [[CDStructureInfo alloc] initWithTypeString:[aStructure typeString]];
            [phase1AnonStructureInfo setObject:info forKey:key];
            [info release];
        } else {
            [info addReferenceCount:1];
        }
    } else {
        key = [[aStructure typeName] description];

        info = [phase1NamedStructureInfo objectForKey:key];
        if (info == nil) {
            info = [[CDStructureInfo alloc] initWithTypeString:[aStructure typeString]];
            [phase1NamedStructureInfo setObject:info forKey:key];
            [info release];
        } else {
            [info addReferenceCount:1];
        }
    }

    //NSLog(@"%s, name=%@, key=%@", _cmd, [[aStructure typeName] description], key);
}

- (void)finishPhase1;
{
    NSLog(@"%s [%@] named count: %u, anon count: %u", _cmd, identifier, [phase1NamedStructureInfo count], [phase1AnonStructureInfo count]);
#if 0
    for (CDStructureInfo *info in [[phase1NamedStructureInfo allValues] sortedArrayUsingSelector:@selector(ascendingCompareByStructureDepth:)]) {
        NSLog(@"%@", [info shortDescription]);
    }

    NSLog(@"----------------------------------------");
#endif
#if 1
    for (CDStructureInfo *info in [[phase1AnonStructureInfo allValues] sortedArrayUsingSelector:@selector(ascendingCompareByStructureDepth:)]) {
        NSLog(@"%@", [info shortDescription]);
    }

    NSLog(@"----------------------------------------");

    // Go through depth 1 named and anon structures...
#endif
}

- (void)mergePhase1StructuresAtDepth:(NSUInteger)depth;
{
    if (debug) NSLog(@"[%@] Merging named phase1 structures at depth %u", identifier, depth);
    for (CDStructureInfo *info in [[phase1NamedStructureInfo allValues] sortedArrayUsingSelector:@selector(ascendingCompareByStructureDepth:)]) {
        if ([[info type] structureDepth] == depth) {
            CDStructureInfo *previousInfo;
            NSMutableArray *dupes;
            NSString *key;

            NSLog(@"Processing %@", [info typeString]);
            // Merge any sub structures/unions first

            key = [[[info type] typeName] description];
            dupes = [phase2NameExceptions objectForKey:key];
            if (dupes == nil) {
                previousInfo = [phase2NamedStructureInfo objectForKey:key];
                if (previousInfo == nil) {
                    if (debug) NSLog(@"[%@] Adding: %@", identifier, key);
                    [phase2NamedStructureInfo setObject:info forKey:key];
                } else {
                    if ([[previousInfo type] canMergeTopLevelWithType:[info type]]) {
                        if (debug) NSLog(@"[%@] Merging: %@", identifier, key);
                        if (debug) NSLog(@"[%@] Map %@ to %@", [previousInfo typeString], [info typeString]);
                        [[previousInfo type] mergeTopLevelWithType:[info type]];
                    } else {
                        if (debug) NSLog(@"[%@] Conflict: %@", identifier, key);
                        if (debug) NSLog(@"old: %@", [[previousInfo type] typeString]);
                        if (debug) NSLog(@"new: %@", [[info type] typeString]);
                        // TODO: Unmap...

                        dupes = [[NSMutableArray alloc] init];
                        [dupes addObject:previousInfo];
                        [dupes addObject:info];
                        [phase2NamedStructureInfo removeObjectForKey:key];
                        [phase2NameExceptions setObject:dupes forKey:key];
                        [dupes release];
                    }
                }
            } else {
                if (debug) NSLog(@"[%@] Adding to exceptions: %@", identifier, key);
                [dupes addObject:info];
            }
        }
    }

    if (debug) NSLog(@"[%@] There are now %u name exceptions", identifier, [phase2NameExceptions count]);


    if (debug) NSLog(@"[%@] Merging anonymous phase1 structures at depth %u", identifier, depth);
    // This is going over the same dictionary, so...
    for (CDStructureInfo *info in [[phase1AnonStructureInfo allValues] sortedArrayUsingSelector:@selector(ascendingCompareByStructureDepth:)]) {
        if ([[info type] structureDepth] == depth) {
            CDStructureInfo *previousInfo;
            NSMutableArray *dupes;
            NSString *key;

            NSLog(@"Processing %@", [info typeString]);
            key = [info typeString];
            dupes = [phase2AnonExceptions objectForKey:key];
            if (dupes == nil) {
                previousInfo = [phase2AnonStructureInfo objectForKey:key];
                if (previousInfo == nil) {
                    if (debug) NSLog(@"[%@] Adding: %@", identifier, key);
                    [phase2AnonStructureInfo setObject:info forKey:key];
                } else {
                    if ([[previousInfo type] canMergeTopLevelWithType:[info type]]) {
                        if (debug) NSLog(@"[%@] Merging: %@", identifier, key);
                        if (debug) NSLog(@"[%@] Map %@ to %@", [previousInfo typeString], [info typeString]);
                        [[previousInfo type] mergeTopLevelWithType:[info type]];
                    } else {
                        if (debug) NSLog(@"[%@] Conflict: %@", identifier, key);
                        if (debug) NSLog(@"old: %@", [[previousInfo type] typeString]);
                        if (debug) NSLog(@"new: %@", [[info type] typeString]);
                        // TODO: Unmap...

                        dupes = [[NSMutableArray alloc] init];
                        [dupes addObject:previousInfo];
                        [dupes addObject:info];
                        [phase2AnonStructureInfo removeObjectForKey:key];
                        [phase2AnonExceptions setObject:dupes forKey:key];
                        [dupes release];
                    }
                }
            } else {
                if (debug) NSLog(@"[%@] Adding to exceptions: %@", identifier, key);
                [dupes addObject:info];
            }
        }
    }

    if (debug) NSLog(@"[%@] There are now %u anonymous exceptions", identifier, [phase2AnonExceptions count]);
}

- (void)logPhase2Info;
{
    NSLog(@" > %s", _cmd);
    NSLog(@"Named: (%u)", [phase2NamedStructureInfo count]);
    for (NSString *key in [[phase2NamedStructureInfo allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        NSLog(@"key: %@, info: %@", key, [phase2NamedStructureInfo objectForKey:key]);
    }
    NSLog(@"--------------------");
    NSLog(@"Named exceptions: (%u)", [phase2NameExceptions count]);
    for (NSString *key in [[phase2NameExceptions allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        NSLog(@"key: %@, infos: %@", key, [phase2NameExceptions objectForKey:key]);
    }
    NSLog(@"--------------------");

    NSLog(@"Anon: (%u)", [phase2AnonStructureInfo count]);
    for (NSString *key in [[phase2AnonStructureInfo allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        NSLog(@"key: %@, info: %@", key, [phase2AnonStructureInfo objectForKey:key]);
    }
    NSLog(@"--------------------");
    NSLog(@"Anon exceptions: (%u)", [phase2AnonExceptions count]);
    for (NSString *key in [[phase2AnonExceptions allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        NSLog(@"key: %@, infos: %@", key, [phase2AnonExceptions objectForKey:key]);
    }
    NSLog(@"--------------------");

    NSLog(@"<  %s", _cmd);
}

@end
