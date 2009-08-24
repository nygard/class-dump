// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import "CDTypeController.h"

#import "CDStructureTable.h"
#import "CDClassDump.h"
#import "CDTypeFormatter.h"
#import "CDType.h"

@implementation CDTypeController

- (id)init;
{
    if ([super init] == nil)
        return nil;

    ivarTypeFormatter = [[CDTypeFormatter alloc] init];
    [ivarTypeFormatter setShouldExpand:NO];
    [ivarTypeFormatter setShouldAutoExpand:YES];
    [ivarTypeFormatter setBaseLevel:1];
    [ivarTypeFormatter setTypeController:self];

    methodTypeFormatter = [[CDTypeFormatter alloc] init];
    [methodTypeFormatter setShouldExpand:NO];
    [methodTypeFormatter setShouldAutoExpand:NO];
    [methodTypeFormatter setBaseLevel:0];
    [methodTypeFormatter setTypeController:self];

    propertyTypeFormatter = [[CDTypeFormatter alloc] init];
    [propertyTypeFormatter setShouldExpand:NO];
    [propertyTypeFormatter setShouldAutoExpand:NO];
    [propertyTypeFormatter setBaseLevel:0];
    [propertyTypeFormatter setTypeController:self];

    structDeclarationTypeFormatter = [[CDTypeFormatter alloc] init];
    [structDeclarationTypeFormatter setShouldExpand:YES]; // But don't expand named struct members...
    [structDeclarationTypeFormatter setShouldAutoExpand:YES];
    [structDeclarationTypeFormatter setBaseLevel:0];
    [structDeclarationTypeFormatter setTypeController:self]; // But need to ignore some things?

    structureTable = [[CDStructureTable alloc] init];
    [structureTable setAnonymousBaseName:@"CDStruct_"];
    [structureTable setIdentifier:@"Structs"];

    unionTable = [[CDStructureTable alloc] init];
    [unionTable setAnonymousBaseName:@"CDUnion_"];
    [unionTable setIdentifier:@"Unions"];

    classDump = nil;

    return self;
}

- (void)dealloc;
{
    [classDump release];

    [ivarTypeFormatter release];
    [methodTypeFormatter release];
    [propertyTypeFormatter release];
    [structDeclarationTypeFormatter release];

    [structureTable release];
    [unionTable release];

    [super dealloc];
}

@synthesize classDump;

- (CDTypeFormatter *)ivarTypeFormatter;
{
    return ivarTypeFormatter;
}

- (CDTypeFormatter *)methodTypeFormatter;
{
    return methodTypeFormatter;
}

- (CDTypeFormatter *)propertyTypeFormatter;
{
    return propertyTypeFormatter;
}

- (CDTypeFormatter *)structDeclarationTypeFormatter;
{
    return structDeclarationTypeFormatter;
}

- (CDType *)typeFormatter:(CDTypeFormatter *)aFormatter replacementForType:(CDType *)aType;
{
    if ([aType type] == '{')
        return [structureTable replacementForType:aType];

    if ([aType type] == '(')
        return [unionTable replacementForType:aType];

    return nil;
}

- (NSString *)typeFormatter:(CDTypeFormatter *)aFormatter typedefNameForStruct:(CDType *)structType level:(NSUInteger)level;
{
    //CDType *searchType;
    //CDStructureTable *targetTable;

    if (level == 0 && aFormatter == structDeclarationTypeFormatter)
        return nil;

    if ([self shouldExpandType:structType] == NO)
        return [self typedefNameForType:structType];

    return nil;
#if 0
    if ([structType type] == '{') {
        targetTable = structureTable;
    } else {
        targetTable = unionTable;
    }

    // We need to catch top level replacements, not just replacements for struct members.
    searchType = [targetTable replacementForType:structType];
    if (searchType == nil)
        searchType = structType;

    return [targetTable typedefNameForStructureType:searchType];
#endif
}

- (void)endPhase:(NSUInteger)phase;
{
    if (phase == 0) {
        [structureTable finishPhase0];
        [unionTable finishPhase0];

        //[structureTable logPhase0Info];

        // At the end of phase 0, we have a dictionary of CDStructureInfos (keyed by the typeString).
        // These record the number of times top level structures were references, their type string, and their type.
#if 0
        {
            NSMutableString *str = [NSMutableString string];

            //[structureTable appendNamedStructuresToString:str formatter:structDeclarationTypeFormatter symbolReferences:nil];

            NSLog(@"str:\n%@", str);
        }
#endif
    }
}

- (void)appendStructuresToString:(NSMutableString *)resultString symbolReferences:(CDSymbolReferences *)symbolReferences;
{
    [structureTable appendNamedStructuresToString:resultString formatter:structDeclarationTypeFormatter symbolReferences:symbolReferences];
    [structureTable appendTypedefsToString:resultString formatter:structDeclarationTypeFormatter symbolReferences:symbolReferences];

    [unionTable appendNamedStructuresToString:resultString formatter:structDeclarationTypeFormatter symbolReferences:symbolReferences];
    [unionTable appendTypedefsToString:resultString formatter:structDeclarationTypeFormatter symbolReferences:symbolReferences];
}

- (void)generateMemberNames;
{
    [structureTable generateMemberNames];
    [unionTable generateMemberNames];
}

//
// CDStructureRegistration Protocol
//

- (void)phase0RegisterStructure:(CDType *)aStructure ivar:(BOOL)isIvar;
{
    if ([aStructure type] == '{') {
        [structureTable phase0RegisterStructure:aStructure ivar:isIvar];
    } else if ([aStructure type] == '(') {
        [unionTable phase0RegisterStructure:aStructure ivar:isIvar];
    } else {
        NSLog(@"%s, unknown structure type: %d", _cmd, [aStructure type]);
    }
}

- (void)phase1RegisterStructure:(CDType *)aStructure;
{
    if ([aStructure type] == '{') {
        [structureTable phase1RegisterStructure:aStructure];
    } else if ([aStructure type] == '(') {
        [unionTable phase1RegisterStructure:aStructure];
    } else {
        NSLog(@"%s, unknown structure type: %d", _cmd, [aStructure type]);
    }
}

// Phase one builds a list of all of the named and unnamed structures.
// It does this by going through all the top level structures we found in phase 0.
- (void)startPhase1;
{
    NSLog(@" > %s", _cmd);
    // Structures and unions can be nested.
    [structureTable phase1WithTypeController:self];
    [unionTable phase1WithTypeController:self];

    [structureTable finishPhase1];
    [unionTable finishPhase1];
    NSLog(@"<  %s", _cmd);
}

- (void)startPhase2;
{
    NSUInteger maxDepth, depth;

    NSLog(@" > %s", _cmd);

    maxDepth = [structureTable phase1_maxDepth];
    if (maxDepth < [unionTable phase1_maxDepth])
        maxDepth = [unionTable phase1_maxDepth];

    for (depth = 1; depth <= maxDepth; depth++) {
        [structureTable phase2AtDepth:depth typeController:self];
        [unionTable phase2AtDepth:depth typeController:self];
    }

    //[structureTable logPhase2Info];

    // do phase2 merge on all the types from phase 0
    [structureTable phase2ReplacementOnPhase0WithTypeController:self];
    [unionTable phase2ReplacementOnPhase0WithTypeController:self];

    // Any info referenced by a method, or with >1 reference, gets typedef'd.
    // - Generate name hash based on full type string at this point
    // - Then fill in unnamed fields

    // Print method/>1 ref names and typedefs
    // Go through all updated phase0_structureInfo types
    // - start merging these into a new table
    //   - If this is the first time a structure has been added:
    //     - add one reference for each subtype
    //   - otherwise just merge them.
    // - end result should be CDStructureInfos with counts and method reference flags
    [structureTable buildPhase3Exceptions];
    [unionTable buildPhase3Exceptions];

    [structureTable phase3WithTypeController:self];
    [structureTable logPhase3Info];

    [unionTable phase3WithTypeController:self];


    [structureTable generateTypedefNames];
    [structureTable generateMemberNames];

    [unionTable generateTypedefNames];
    [unionTable generateMemberNames];

    // - All named structures (minus exceptions like struct _flags) get declared at the top level
    // - All anonymous structures (minus exceptions) referenced by a method
    //                                            OR references >1 time gets typedef'd at the top and referenced by typedef subsequently
    // Celebrate!

    // Then... what do we do when printing ivars/method types?
    // CDTypeController - (BOOL)shouldExpandType:(CDType *)type;
    // CDTypeController - (NSString *)typedefNameForType:(CDType *)type;

#if 1
    {
        NSMutableString *str;

        str = [NSMutableString string];
        [structureTable appendNamedStructuresToString:str formatter:structDeclarationTypeFormatter symbolReferences:nil];
        [unionTable appendNamedStructuresToString:str formatter:structDeclarationTypeFormatter symbolReferences:nil];
        [str writeToFile:@"/tmp/out.struct" atomically:NO encoding:NSUTF8StringEncoding error:NULL];

        str = [NSMutableString string];
        [structureTable appendTypedefsToString:str formatter:structDeclarationTypeFormatter symbolReferences:nil];
        [unionTable appendTypedefsToString:str formatter:structDeclarationTypeFormatter symbolReferences:nil];
        [str writeToFile:@"/tmp/out.typedef" atomically:NO encoding:NSUTF8StringEncoding error:NULL];
        //NSLog(@"str =\n%@", str);
    }
#endif
    exit(99);

    NSLog(@"<  %s", _cmd);
}

- (BOOL)shouldShowName:(NSString *)name;
{
    return ([classDump shouldMatchRegex] == NO) || [classDump regexMatchesString:name];
}

- (CDType *)phase2ReplacementForType:(CDType *)type;
{
    if ([type type] == '{')
        return [structureTable phase2ReplacementForType:type];

    if ([type type] == '(')
        return [unionTable phase2ReplacementForType:type];

    return nil;
}

- (void)phase3RegisterStructure:(CDType *)aStructure;
{
    if ([aStructure type] == '{')
        [structureTable phase3RegisterStructure:aStructure count:1 usedInMethod:NO typeController:self];

    if ([aStructure type] == '(')
        [unionTable phase3RegisterStructure:aStructure count:1 usedInMethod:NO typeController:self];
}

- (BOOL)shouldExpandType:(CDType *)type;
{
    if ([type type] == '{')
        return [structureTable shouldExpandType:type];

    if ([type type] == '(')
        return [unionTable shouldExpandType:type];

    return NO;
}

- (NSString *)typedefNameForType:(CDType *)type;
{
    if ([type type] == '{')
        return [structureTable typedefNameForType:type];

    if ([type type] == '(')
        return [unionTable typedefNameForType:type];

    return nil;
}

@end
