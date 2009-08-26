// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import "CDStructureTable.h"

#import "NSArray-Extensions.h"
#import "NSError-CDExtensions.h"
#import "NSString-Extensions.h"
#import "CDClassDump.h"
#import "CDSymbolReferences.h"
#import "CDType.h"
#import "CDTypeController.h"
#import "CDTypeFormatter.h"
#import "CDTypeName.h"
#import "CDTypeParser.h"
#import "CDStructureInfo.h"

static BOOL debug = NO;
static BOOL debugNamedStructures = NO;
static BOOL debugAnonStructures = NO;

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

    phase3_namedStructureInfo = [[NSMutableDictionary alloc] init];
    phase3_anonStructureInfo = [[NSMutableDictionary alloc] init];
    phase3_nameExceptions = [[NSMutableSet alloc] init];
    phase3_anonExceptions = [[NSMutableDictionary alloc] init];

    phase3_inMethodNameExceptions = [[NSMutableSet alloc] init];
    phase3_bareAnonExceptions = [[NSMutableSet alloc] init];

    flags.shouldDebug = NO;

    debugNames = [[NSMutableSet alloc] init];
    debugAnon = [[NSMutableSet alloc] init];

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

    [phase3_namedStructureInfo release];
    [phase3_anonStructureInfo release];
    [phase3_nameExceptions release];
    [phase3_anonExceptions release];

    [phase3_inMethodNameExceptions release];
    [phase3_bareAnonExceptions release];

    [debugNames release];
    [debugAnon release];

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

// TODO (2003-12-23): Add option to show/hide this section
// TODO (2003-12-23): sort by name or by dependency
// TODO (2003-12-23): declare in modules where they were first used

- (void)appendNamedStructuresToString:(NSMutableString *)resultString
                            formatter:(CDTypeFormatter *)aTypeFormatter
                     symbolReferences:(CDSymbolReferences *)symbolReferences
                             markName:(NSString *)markName;
{
    BOOL hasAddedMark = NO;
    BOOL hasShownExceptions = NO;

    for (NSString *key in [[phase3_namedStructureInfo allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        CDStructureInfo *info;
        BOOL shouldShow;

        info = [phase3_namedStructureInfo objectForKey:key];
        shouldShow = ![self shouldExpandStructureInfo:info];
        if (shouldShow || debugNamedStructures) {
            CDType *type;

            if (hasAddedMark == NO) {
                [resultString appendFormat:@"#pragma mark %@\n\n", markName];
                hasAddedMark = YES;
            }

            type = [info type];
            if ([[aTypeFormatter typeController] shouldShowName:[[type typeName] description]]) {
                NSString *formattedString;

                if (debugNamedStructures) {
                    [resultString appendFormat:@"// would normally show? %u\n", shouldShow];
                    [resultString appendFormat:@"// depth: %u, ref count: %u, used in method? %u\n", [[info type] structureDepth], [info referenceCount], [info isUsedInMethod]];
                }
                formattedString = [aTypeFormatter formatVariable:nil parsedType:type symbolReferences:symbolReferences];
                if (formattedString != nil) {
                    [resultString appendString:formattedString];
                    [resultString appendString:@";\n\n"];
                }
            }
        }
    }

    for (CDStructureInfo *info in [phase2_nameExceptions sortedArrayUsingSelector:@selector(ascendingCompareByStructureDepth:)]) {
        if ([phase3_inMethodNameExceptions containsObject:[info name]]) {
            CDType *type;

            if (hasAddedMark == NO) {
                [resultString appendFormat:@"#pragma mark %@\n\n", markName];
                hasAddedMark = YES;
            }

            if (hasShownExceptions == NO) {
                [resultString appendString:@"#if 0\n"];
                [resultString appendString:@"// Names with conflicting types, that are used in methods:\n"];
                hasShownExceptions = YES;
            }

            type = [info type];
            if ([[aTypeFormatter typeController] shouldShowName:[[type typeName] description]]) {
                NSString *formattedString;

                if (debugNamedStructures) {
                    [resultString appendFormat:@"// depth: %u, ref count: %u, used in method? %u\n", [[info type] structureDepth], [info referenceCount], [info isUsedInMethod]];
                }
                formattedString = [aTypeFormatter formatVariable:nil parsedType:type symbolReferences:symbolReferences];
                if (formattedString != nil) {
                    [resultString appendString:formattedString];
                    [resultString appendString:@";\n\n"];
                }
            }
        }
    }
    if (hasShownExceptions)
        [resultString appendString:@"#endif\n\n"];

    if (debugNamedStructures) {
        [resultString appendString:@"\n// Name exceptions:\n"];
        for (NSString *str in [[phase3_nameExceptions allObjects] sortedArrayUsingSelector:@selector(compare:)])
            [resultString appendFormat:@"// %@\n", str];
        [resultString appendString:@"\n"];
    }
}

- (void)appendTypedefsToString:(NSMutableString *)resultString
                     formatter:(CDTypeFormatter *)aTypeFormatter
              symbolReferences:(CDSymbolReferences *)symbolReferences
                      markName:(NSString *)markName;
{
    BOOL hasAddedMark = NO;
    BOOL hasShownExceptions = NO;

    for (CDStructureInfo *info in [[phase3_anonStructureInfo allValues] sortedArrayUsingSelector:@selector(ascendingCompareByStructureDepth:)]) {
        BOOL shouldShow;

        shouldShow = ![self shouldExpandStructureInfo:info];
        if (shouldShow || debugAnonStructures) {
            NSString *formattedString;

            if (hasAddedMark == NO) {
                [resultString appendFormat:@"#pragma mark %@\n\n", markName];
                hasAddedMark = YES;
            }

            if (debugAnonStructures) {
                [resultString appendFormat:@"// would normally show? %u\n", shouldShow];
                [resultString appendFormat:@"// %@\n", [[info type] reallyBareTypeString]];
                [resultString appendFormat:@"// depth: %u, ref: %u, used in method? %u\n", [[info type] structureDepth], [info referenceCount], [info isUsedInMethod]];
            }
            formattedString = [aTypeFormatter formatVariable:nil parsedType:[info type] symbolReferences:symbolReferences];
            if (formattedString != nil) {
                [resultString appendFormat:@"typedef %@ %@;\n\n", formattedString, [info typedefName]];
            }
        }
    }

    // TODO (2009-08-25): Need same ref count rules for anon exceptions.
    for (CDStructureInfo *info in [[phase3_anonExceptions allValues] sortedArrayUsingSelector:@selector(ascendingCompareByStructureDepth:)]) {
        if ([phase3_bareAnonExceptions containsObject:[[info type] reallyBareTypeString]]) {
            NSString *formattedString;

            if (hasAddedMark == NO) {
                [resultString appendFormat:@"#pragma mark %@\n\n", markName];
                hasAddedMark = YES;
            }

            if (hasShownExceptions == NO) {
                [resultString appendString:@"// Ambiguous\n"];
                hasShownExceptions = YES;
            }

            if (debugAnonStructures) {
                [resultString appendFormat:@"// %@\n", [[info type] reallyBareTypeString]];
                [resultString appendFormat:@"// depth: %u, ref: %u, used in method? %u\n", [[info type] structureDepth], [info referenceCount], [info isUsedInMethod]];
            }
            formattedString = [aTypeFormatter formatVariable:nil parsedType:[info type] symbolReferences:symbolReferences];
            if (formattedString != nil) {
                //[resultString appendFormat:@"%@;\n\n", formattedString];
                [resultString appendFormat:@"typedef %@ %@;\n\n", formattedString, [info typedefName]];
            }
        }
    }

    if (debugAnonStructures) {
        [resultString appendString:@"\n// Anon exceptions:\n"];
        for (NSString *str in [[phase3_anonExceptions allKeys] sortedArrayUsingSelector:@selector(compare:)])
            [resultString appendFormat:@"// %@\n", str];
        [resultString appendString:@"\n"];
    }
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
    for (CDStructureInfo *info in [phase0_structureInfo allValues]) {
        [[info type] phase0RecursivelyFixStructureNames];
    }

    if ([debugNames count] > 0) {
        NSLog(@"======================================================================");
        NSLog(@"[%@] %s", identifier, _cmd);
        NSLog(@"debug names: %@", [[debugNames allObjects] componentsJoinedByString:@", "]);
        for (CDStructureInfo *info in [[phase0_structureInfo allValues] sortedArrayUsingSelector:@selector(ascendingCompareByStructureDepth:)]) {
            if ([debugNames containsObject:[[[info type] typeName] description]])
                NSLog(@"%@", [info shortDescription]);
        }
        NSLog(@"======================================================================");
    }

    if ([debugAnon count] > 0) {
        NSLog(@"======================================================================");
        NSLog(@"[%@] %s", identifier, _cmd);
        NSLog(@"debug anon: %@", [[debugAnon allObjects] componentsJoinedByString:@", "]);
        for (CDStructureInfo *info in [[phase0_structureInfo allValues] sortedArrayUsingSelector:@selector(ascendingCompareByStructureDepth:)]) {
            if ([debugAnon containsObject:[[info type] reallyBareTypeString]])
                NSLog(@"%@", [info shortDescription]);
        }
        NSLog(@"======================================================================");
    }
}

- (void)logPhase0Info;
{
    NSLog(@"======================================================================");
    NSLog(@"[%@] %s", identifier, _cmd);
    for (CDStructureInfo *info in [[phase0_structureInfo allValues] sortedArrayUsingSelector:@selector(ascendingCompareByStructureDepth:)]) {
        NSLog(@"%@", [info shortDescription]);
    }
    NSLog(@"======================================================================");
}

- (void)generateTypedefNames;
{
    for (CDStructureInfo *info in [phase3_anonStructureInfo allValues]) {
        [info generateTypedefName:anonymousBaseName];
    }

    // And do the same for each of the anon exceptions
    for (CDStructureInfo *info in [phase3_anonExceptions allValues]) {
        [info generateTypedefName:anonymousBaseName];
    }
}

- (void)generateMemberNames;
{
    for (CDStructureInfo *info in [phase3_namedStructureInfo allValues]) {
        [[info type] generateMemberNames];
    }

    for (CDStructureInfo *info in [phase3_anonStructureInfo allValues]) {
        [[info type] generateMemberNames];
    }

    // And do the same for each of the anon exceptions
    for (CDStructureInfo *info in [phase3_anonExceptions allValues]) {
        [[info type] generateMemberNames];
    }
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
    //NSLog(@"%s ======================================================================", _cmd);

    // The deepest union may not be at the top level (buried in a structure instead), so need to get the depth here.
    // But we'll take the max of structure and union depths in the CDTypeController anyway.

    for (CDStructureInfo *info in [phase1_structureInfo allValues]) {
        NSUInteger depth;

        depth = [[info type] structureDepth];
        if (phase1_maxDepth < depth)
            phase1_maxDepth = depth;
    }
    //NSLog(@"[%@] Maximum structure depth is: %u", identifier, phase1_maxDepth);

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

        //NSLog(@"depth groups: %@", [[phase1_groupedByDepth allKeys] sortedArrayUsingSelector:@selector(compare:)]);
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

    //NSLog(@"[%@] %s, depth: %u", identifier, _cmd, depth);
    depthKey = [NSNumber numberWithUnsignedInt:depth];
    infos = [phase1_groupedByDepth objectForKey:depthKey];

    for (CDStructureInfo *info in infos) {
        // recursively (bottom up) try to merge substructures into that type, to get names/full types
        //NSLog(@"----------------------------------------");
        //NSLog(@"Trying phase2Merge with on %@", [[info type] typeString]);
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
#if 0
                    if ([info isUsedInMethod])
                        [combined setIsUsedInMethod:YES];
#endif
                } else {
                    canBeCombined = NO;
                    break;
                }
            }
        }

        if (canBeCombined) {
            [phase2_namedStructureInfo setObject:combined forKey:key];
        } else {
            if (debugAnonStructures) {
                NSLog(@"----------------------------------------");
                NSLog(@"Can't be combined: %@", key);
                NSLog(@"group: %@", group);
            }
            [phase2_nameExceptions addObjectsFromArray:group];
        }

        [combined release];
    }

    //NSLog(@"======================================================================");
    for (NSString *key in [anonDict allKeys]) {
        NSMutableArray *group;
        CDStructureInfo *combined = nil;
        BOOL canBeCombined = YES;

        //NSLog(@"key... %@", key);
        group = [anonDict objectForKey:key];
        for (CDStructureInfo *info in group) {
            if (combined == nil) {
                combined = [info copy];
                //NSLog(@"info: %@", [info shortDescription]);
                //NSLog(@"combined: %@", [combined shortDescription]);
            } else {
                //NSLog(@"old: %@", [combined shortDescription]);
                //NSLog(@"new: %@", [info shortDescription]);
                if ([[combined type] canMergeWithType:[info type]]) {
                    [[combined type] mergeWithType:[info type]];
                    [combined addReferenceCount:[info referenceCount]];
#if 0
                    if ([info isUsedInMethod])
                        [combined setIsUsedInMethod:YES];
#endif
                } else {
                    if (debugAnonStructures) {
                        NSLog(@"previous: %@", [[combined type] typeString]);
                        NSLog(@"    This: %@", [[info type] typeString]);
                    }
                    canBeCombined = NO;
                    break;
                }
            }
        }

        if (canBeCombined) {
            [phase2_anonStructureInfo setObject:combined forKey:key];
        } else {
            if (debugAnonStructures) {
                NSLog(@"----------------------------------------");
                NSLog(@"Can't be combined: %@", key);
                NSLog(@"group: %@", group);
            }
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

- (void)finishPhase2;
{
    if ([debugNames count] > 0) {
        NSLog(@"======================================================================");
        NSLog(@"[%@] %s", identifier, _cmd);
        NSLog(@"names: %@", [[debugNames allObjects] componentsJoinedByString:@", "]);
        for (CDStructureInfo *info in [[phase2_namedStructureInfo allValues] sortedArrayUsingSelector:@selector(ascendingCompareByStructureDepth:)]) {
            if ([debugNames containsObject:[[[info type] typeName] description]])
                NSLog(@"%@", [info shortDescription]);
        }
        NSLog(@"======================================================================");
    }

    if ([debugAnon count] > 0) {
        NSLog(@"======================================================================");
        NSLog(@"[%@] %s", identifier, _cmd);
        NSLog(@"debug anon: %@", [[debugAnon allObjects] componentsJoinedByString:@", "]);
        for (CDStructureInfo *info in [[phase2_anonStructureInfo allValues] sortedArrayUsingSelector:@selector(ascendingCompareByStructureDepth:)]) {
            if ([debugAnon containsObject:[[info type] reallyBareTypeString]])
                NSLog(@"%@", [info shortDescription]);
        }
        NSLog(@"======================================================================");
    }
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
    //NSLog(@"[%@]  > %s", identifier, _cmd);

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

    //NSLog(@"[%@] <  %s", identifier, _cmd);
}

// Go through all updated phase0_structureInfo types
// - start merging these into a new table
//   - If this is the first time a structure has been added:
//     - add one reference for each subtype
//   - otherwise just merge them.
// - end result should be CDStructureInfos with counts and method reference flags

- (void)buildPhase3Exceptions;
{
    for (CDStructureInfo *info in phase2_nameExceptions)
        [phase3_nameExceptions addObject:[[[info type] typeName] description]];

    for (CDStructureInfo *info in phase2_anonExceptions) {
        CDStructureInfo *newInfo;

        newInfo = [info copy];
        [phase3_anonExceptions setObject:newInfo forKey:[[newInfo type] typeString]];
        [newInfo release];
    }

    //NSLog(@"phase3 name exceptions: %@", [[phase3_nameExceptions allObjects] componentsJoinedByString:@", "]);
    //NSLog(@"phase3 anon exceptions: %@", [[phase3_anonExceptions allKeys] componentsJoinedByString:@"\n"]);
    //exit(99);
}

- (void)phase3WithTypeController:(CDTypeController *)typeController;
{
    //NSLog(@"[%@]  > %s", identifier, _cmd);

    for (CDStructureInfo *info in [[phase0_structureInfo allValues] sortedArrayUsingSelector:@selector(ascendingCompareByStructureDepth:)]) {
        [self phase3RegisterStructure:[info type] count:[info referenceCount] usedInMethod:[info isUsedInMethod] typeController:typeController];
    }

    //NSLog(@"[%@] <  %s", identifier, _cmd);
}

- (void)phase3RegisterStructure:(CDType *)aStructure
                          count:(NSUInteger)referenceCount
                   usedInMethod:(BOOL)isUsedInMethod
                 typeController:(CDTypeController *)typeController;
{
    NSString *name;

    //NSLog(@"[%@]  > %s", identifier, _cmd);

    name = [[aStructure typeName] description];
    if ([@"?" isEqualToString:name]) {
        NSString *key;
        CDStructureInfo *info;

        key = [aStructure reallyBareTypeString];
        //NSLog(@"key: %@, isUsedInMethod: %u", key, isUsedInMethod);
        if ([phase3_anonExceptions objectForKey:[aStructure typeString]] != nil) {
            if (debugAnonStructures) NSLog(@"%s, anon key %@ has exception from phase 2", _cmd, [aStructure typeString]);
        } else {
            info = [phase3_anonStructureInfo objectForKey:key];
            if (info == nil) {
                info = [[CDStructureInfo alloc] initWithTypeString:[aStructure typeString]];
                [info setReferenceCount:referenceCount];
                if (isUsedInMethod)
                    [info setIsUsedInMethod:isUsedInMethod];
                [phase3_anonStructureInfo setObject:info forKey:key];
                [info release];

                // And then... add 1 reference for each substructure, stopping recursion when we've encountered a previous structure
                [aStructure phase3RegisterMembersWithTypeController:typeController];
            } else {
                [info addReferenceCount:referenceCount];
                if (isUsedInMethod)
                    [info setIsUsedInMethod:isUsedInMethod];
            }
        }
    } else {
        CDStructureInfo *info;

        if ([debugNames containsObject:name]) NSLog(@"[%@] %s, type= %@", identifier, _cmd, [aStructure typeString]);
        //NSLog(@"[%@] %s, name: %@", identifier, _cmd, name);
        if ([phase3_nameExceptions containsObject:name]) {
            if (debugNamedStructures) NSLog(@"%s, name %@ has exception from phase 2", _cmd, name);
            if (isUsedInMethod)
                [phase3_inMethodNameExceptions addObject:name];
        } else {
            info = [phase3_namedStructureInfo objectForKey:name];
            if (info == nil) {
                if ([debugNames containsObject:name]) NSLog(@"[%@] %s, info was nil for %@", identifier, _cmd, name);
                info = [[CDStructureInfo alloc] initWithTypeString:[aStructure typeString]];
                [info setReferenceCount:referenceCount];
                if (isUsedInMethod)
                    [info setIsUsedInMethod:isUsedInMethod];
                [phase3_namedStructureInfo setObject:info forKey:name];
                [info release];

                // And then... add 1 reference for each substructure, stopping recursion when we've encountered a previous structure
                [aStructure phase3RegisterMembersWithTypeController:typeController];
            } else {
                if ([debugNames containsObject:name]) NSLog(@"[%@] %s, info before: %@", identifier, _cmd, [info shortDescription]);
                // Handle the case where {foo} occurs before {foo=iii}
                if ([[[info type] members] count] == 0) {
                    [[info type] mergeWithType:aStructure];

                    // And then... add 1 reference for each substructure, stopping recursion when we've encountered a previous structure
                    [aStructure phase3RegisterMembersWithTypeController:typeController];
                }
                [info addReferenceCount:referenceCount];
                if (isUsedInMethod)
                    [info setIsUsedInMethod:isUsedInMethod];
                if ([debugNames containsObject:name]) {
                    NSLog(@"[%@] %s, added ref count: %u, isUsedInMethod: %u", identifier, _cmd, referenceCount, isUsedInMethod);
                    NSLog(@"[%@] %s, info after: %@", identifier, _cmd, [info shortDescription]);
                }
            }
        }
    }

    //NSLog(@"[%@] <  %s", identifier, _cmd);
}

- (void)finishPhase3;
{
    for (CDStructureInfo *info in [phase3_anonExceptions allValues]) {
        if ([[[info type] reallyBareTypeString] isEqualToString:[[info type] typeString]]) {
            [phase3_bareAnonExceptions addObject:[[info type] typeString]];
        }
    }
    NSLog(@"phase3_bareAnonExceptions: %@", phase3_bareAnonExceptions);

    if ([debugNames count] > 0) {
        NSLog(@"======================================================================");
        NSLog(@"[%@] %s", identifier, _cmd);
        NSLog(@"names: %@", [[debugNames allObjects] componentsJoinedByString:@", "]);
        for (CDStructureInfo *info in [[phase3_namedStructureInfo allValues] sortedArrayUsingSelector:@selector(ascendingCompareByStructureDepth:)]) {
            if ([debugNames containsObject:[[[info type] typeName] description]])
                NSLog(@"%@", [info shortDescription]);
        }
        for (NSString *str in debugNames)
            if ([phase3_nameExceptions containsObject:str])
                NSLog(@"%@ is in the name exceptions", str);
        NSLog(@"======================================================================");
    }

    if ([debugAnon count] > 0) {
        NSLog(@"======================================================================");
        NSLog(@"[%@] %s", identifier, _cmd);
        NSLog(@"debug anon: %@", [[debugAnon allObjects] componentsJoinedByString:@", "]);
        for (CDStructureInfo *info in [[phase3_anonStructureInfo allValues] sortedArrayUsingSelector:@selector(ascendingCompareByStructureDepth:)]) {
            if ([debugAnon containsObject:[[info type] reallyBareTypeString]])
                NSLog(@"%@", [info shortDescription]);
        }
        for (NSString *str in debugAnon)
            if ([phase3_anonExceptions objectForKey:str] != nil)
                NSLog(@"%@ is in the anon exceptions", str);
        NSLog(@"======================================================================");
    }
}

- (void)logPhase3Info;
{
    NSLog(@"[%@]  > %s", identifier, _cmd);

    NSLog(@"----------------------------------------------------------------------");
    NSLog(@"named:");
    for (NSString *name in [[phase3_namedStructureInfo allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        CDStructureInfo *info;

        info = [phase3_namedStructureInfo objectForKey:name];
        NSLog(@"%@", [info shortDescription]);
    }

    NSLog(@"----------------------------------------------------------------------");
    NSLog(@"anon:");
    for (CDStructureInfo *info in [[phase3_anonStructureInfo allValues] sortedArrayUsingSelector:@selector(ascendingCompareByStructureDepth:)]) {
        NSLog(@"%@", [info shortDescription]);
    }

    NSLog(@"[%@] <  %s", identifier, _cmd);
}

- (CDType *)phase3ReplacementForType:(CDType *)type;
{
    NSString *name;

    name = [[type typeName] description];
    if ([@"?" isEqualToString:name]) {
        return [(CDStructureInfo *)[phase3_anonStructureInfo objectForKey:[type reallyBareTypeString]] type];
    } else {
        return [(CDStructureInfo *)[phase3_namedStructureInfo objectForKey:name] type];
    }

    return nil;
}

- (BOOL)shouldExpandStructureInfo:(CDStructureInfo *)info;
{
    return (info == nil)
        || ([info isUsedInMethod] == NO
            && [info referenceCount] < 2
            && (([[info name] hasPrefix:@"_"] && [[info name] hasUnderscoreCapitalPrefix] == NO)
                || [@"?" isEqualToString:[info name]]));
}

// For automatic expansion?
- (BOOL)shouldExpandType:(CDType *)type;
{
    NSString *name;
    CDStructureInfo *info;

    name = [[type typeName] description];
    if ([@"?" isEqualToString:name]) {
        NSString *key;

        key = [type reallyBareTypeString];
        info = [phase3_anonStructureInfo objectForKey:key];
        if (info == nil) {
            if ([phase3_anonExceptions objectForKey:[type typeString]] != nil) {
                //NSLog(@"Never expand anon exception: %@", [type typeString]);
                return NO;
            }
        }
    } else {
        info = [phase3_namedStructureInfo objectForKey:name];
    }

    return [self shouldExpandStructureInfo:info];
}

- (NSString *)typedefNameForType:(CDType *)type;
{
    CDStructureInfo *info;

    info = [phase3_anonStructureInfo objectForKey:[type reallyBareTypeString]];
    if (info == nil) {
        info = [phase3_anonExceptions objectForKey:[type typeString]];
        //NSLog(@"fallback typedef info? %@ -- %@", [info shortDescription], [info typedefName]);
    }

    return [info typedefName];
}

- (void)debugName:(NSString *)name;
{
    [debugNames addObject:name];
}

- (void)debugAnon:(NSString *)str;
{
    [debugAnon addObject:str];
}

@end
