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
    [structureTable setAnonymousBaseName:@"CDAnonymousStruct"];
    [structureTable setIdentifier:@"Structs"];

    unionTable = [[CDStructureTable alloc] init];
    [unionTable setAnonymousBaseName:@"CDAnonymousUnion"];
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
    CDType *searchType;
    CDStructureTable *targetTable;

    if (level == 0 && aFormatter == structDeclarationTypeFormatter)
        return nil;

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
}

- (void)endPhase:(NSUInteger)phase;
{
    if (phase == 0) {
        [structureTable finishPhase0];
        [unionTable finishPhase0];

        // At the end of phase 0, we have a dictionary of CDStructureInfos (keyed by the typeString).
        // These record the number of times top level structures were references, their type string, and their type.
#if 0
        {
            NSMutableString *str = [NSMutableString string];

            [structureTable appendNamedStructuresToString:str formatter:structDeclarationTypeFormatter symbolReferences:nil];

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


    {
        NSMutableString *str;

        str = [NSMutableString string];
        [self appendStructuresToString:str symbolReferences:nil];
        NSLog(@"str =\n%@", str);
    }

    exit(99);
#if 0
    [structureTable mergePhase1StructuresAtDepth:1];
    [unionTable mergePhase1StructuresAtDepth:1];

    [structureTable logPhase2Info];
    [unionTable logPhase2Info];

    NSLog(@"======================================================================");
    NSLog(@"======================================================================");
    NSLog(@"======================================================================");
    NSLog(@"======================================================================");
    NSLog(@"======================================================================");

    [structureTable mergePhase1StructuresAtDepth:2];
    [unionTable mergePhase1StructuresAtDepth:2];

    [structureTable logPhase2Info];
    [unionTable logPhase2Info];
#endif
    NSLog(@"<  %s", _cmd);
}

- (BOOL)shouldShowName:(NSString *)name;
{
    return ([classDump shouldMatchRegex] == NO) || [classDump regexMatchesString:name];
}

@end
