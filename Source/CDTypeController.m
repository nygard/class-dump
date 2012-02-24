// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDTypeController.h"

#import "CDStructureTable.h"
#import "CDClassDump.h"
#import "CDTypeFormatter.h"
#import "CDType.h"

static BOOL debug = NO;

@interface CDTypeController ()

@property (readonly) CDClassDump *classDump;

- (void)generateTypedefNames;
- (void)generateMemberNames;

- (void)startPhase1;
- (void)startPhase2;
- (void)startPhase3;

@end

#pragma mark -

@implementation CDTypeController
{
    CDClassDump *nonretained_classDump; // passed during formatting, to get at options.
    
    CDTypeFormatter *ivarTypeFormatter;
    CDTypeFormatter *methodTypeFormatter;
    CDTypeFormatter *propertyTypeFormatter;
    CDTypeFormatter *structDeclarationTypeFormatter;
    
    CDStructureTable *structureTable;
    CDStructureTable *unionTable;
}

- (id)initWithClassDump:(CDClassDump *)classDump;
{
    if ((self = [super init])) {
        nonretained_classDump = classDump;
        
        ivarTypeFormatter = [[CDTypeFormatter alloc] init];
        ivarTypeFormatter.shouldExpand = NO;
        ivarTypeFormatter.shouldAutoExpand = YES;
        ivarTypeFormatter.baseLevel = 1;
        ivarTypeFormatter.typeController = self;
        
        methodTypeFormatter = [[CDTypeFormatter alloc] init];
        methodTypeFormatter.shouldExpand = NO;
        methodTypeFormatter.shouldAutoExpand = NO;
        methodTypeFormatter.baseLevel = 0;
        methodTypeFormatter.typeController = self;
        
        propertyTypeFormatter = [[CDTypeFormatter alloc] init];
        propertyTypeFormatter.shouldExpand = NO;
        propertyTypeFormatter.shouldAutoExpand = NO;
        propertyTypeFormatter.baseLevel = 0;
        propertyTypeFormatter.typeController = self;
        
        structDeclarationTypeFormatter = [[CDTypeFormatter alloc] init];
        structDeclarationTypeFormatter.shouldExpand = YES; // But don't expand named struct members...
        structDeclarationTypeFormatter.shouldAutoExpand = YES;
        structDeclarationTypeFormatter.baseLevel = 0;
        structDeclarationTypeFormatter.typeController = self; // But need to ignore some things?
        
        structureTable = [[CDStructureTable alloc] init];
        structureTable.anonymousBaseName = @"CDStruct_";
        structureTable.identifier = @"Structs";
        
        unionTable = [[CDStructureTable alloc] init];
        unionTable.anonymousBaseName = @"CDUnion_";
        unionTable.identifier = @"Unions";
        
        //[structureTable debugName:@"_xmlSAXHandler"];
        //[structureTable debugName:@"UCKeyboardTypeHeader"];
        //[structureTable debugName:@"UCKeyboardLayout"];
        //[structureTable debugName:@"ppd_group_s"];
        //[structureTable debugName:@"stat"];
        //[structureTable debugName:@"timespec"];
        //[structureTable debugName:@"AudioUnitEvent"];
        //[structureTable debugAnon:@"{?=II}"];
        //[structureTable debugName:@"_CommandStackEntry"];
        //[structureTable debugName:@"_flags"];
    }

    return self;
}

- (void)dealloc;
{
    [ivarTypeFormatter release];
    [methodTypeFormatter release];
    [propertyTypeFormatter release];
    [structDeclarationTypeFormatter release];

    [structureTable release];
    [unionTable release];

    [super dealloc];
}

#pragma mark -

@synthesize classDump = nonretained_classDump;

@synthesize ivarTypeFormatter;
@synthesize methodTypeFormatter;
@synthesize propertyTypeFormatter;
@synthesize structDeclarationTypeFormatter;

#pragma mark -

- (BOOL)shouldShowIvarOffsets;
{
    return self.classDump.shouldShowIvarOffsets;
}

- (BOOL)shouldShowMethodAddresses;
{
    return self.classDump.shouldShowMethodAddresses;
}

- (BOOL)targetArchUses64BitABI;
{
    return CDArchUses64BitABI(self.classDump.targetArch);
}

#pragma mark -

- (CDType *)typeFormatter:(CDTypeFormatter *)typeFormatter replacementForType:(CDType *)type;
{
#if 0
    if (type.type == '{') return [structureTable replacementForType:type];
    if (type.type == '(') return [unionTable     replacementForType:type];
#endif
    return nil;
}

- (NSString *)typeFormatter:(CDTypeFormatter *)typeFormatter typedefNameForStruct:(CDType *)structType level:(NSUInteger)level;
{
    if (level == 0 && typeFormatter == structDeclarationTypeFormatter)
        return nil;

    if ([self shouldExpandType:structType] == NO)
        return [self typedefNameForType:structType];

    return nil;
}

- (void)appendStructuresToString:(NSMutableString *)resultString symbolReferences:(CDSymbolReferences *)symbolReferences;
{
    [structureTable appendNamedStructuresToString:resultString formatter:structDeclarationTypeFormatter symbolReferences:symbolReferences markName:@"Named Structures"];
    [structureTable appendTypedefsToString:resultString        formatter:structDeclarationTypeFormatter symbolReferences:symbolReferences markName:@"Typedef'd Structures"];

    [unionTable appendNamedStructuresToString:resultString formatter:structDeclarationTypeFormatter symbolReferences:symbolReferences markName:@"Named Unions"];
    [unionTable appendTypedefsToString:resultString        formatter:structDeclarationTypeFormatter symbolReferences:symbolReferences markName:@"Typedef'd Unions"];
}

// Call this before calling generateMemberNames.
- (void)generateTypedefNames;
{
    [structureTable generateTypedefNames];
    [unionTable     generateTypedefNames];
}

- (void)generateMemberNames;
{
    [structureTable generateMemberNames];
    [unionTable     generateMemberNames];
}

#pragma mark - Run phase 1+

- (void)workSomeMagic;
{
    [self startPhase1];
    [self startPhase2];
    [self startPhase3];

    [self generateTypedefNames];
    [self generateMemberNames];

    if (debug) {
        NSMutableString *str = [NSMutableString string];
        [structureTable appendNamedStructuresToString:str formatter:structDeclarationTypeFormatter symbolReferences:nil markName:@"Named Structures"];
        [unionTable     appendNamedStructuresToString:str formatter:structDeclarationTypeFormatter symbolReferences:nil markName:@"Named Unions"];
        [str writeToFile:@"/tmp/out.struct" atomically:NO encoding:NSUTF8StringEncoding error:NULL];

        str = [NSMutableString string];
        [structureTable appendTypedefsToString:str formatter:structDeclarationTypeFormatter symbolReferences:nil markName:@"Typedef'd Structures"];
        [unionTable     appendTypedefsToString:str formatter:structDeclarationTypeFormatter symbolReferences:nil markName:@"Typedef'd Unions"];
        [str writeToFile:@"/tmp/out.typedef" atomically:NO encoding:NSUTF8StringEncoding error:NULL];
        //NSLog(@"str =\n%@", str);
    }
}

#pragma mark - Phase 0

- (void)phase0RegisterStructure:(CDType *)structure usedInMethod:(BOOL)isUsedInMethod;
{
    if (structure.type == '{') {
        [structureTable phase0RegisterStructure:structure usedInMethod:isUsedInMethod];
    } else if (structure.type == '(') {
        [unionTable     phase0RegisterStructure:structure usedInMethod:isUsedInMethod];
    } else {
        NSLog(@"%s, unknown structure type: %d", __cmd, structure.type);
    }
}

- (void)endPhase:(NSUInteger)phase;
{
    if (phase == 0) {
        [structureTable finishPhase0];
        [unionTable     finishPhase0];
    }
}

#pragma mark - Phase 1

// Phase one builds a list of all of the named and unnamed structures.
// It does this by going through all the top level structures we found in phase 0.
- (void)startPhase1;
{
    //NSLog(@" > %s", __cmd);
    // Structures and unions can be nested, so do phase 1 on each table before finishing the phase.
    [structureTable phase1WithTypeController:self];
    [unionTable     phase1WithTypeController:self];

    [structureTable finishPhase1];
    [unionTable     finishPhase1];
    //NSLog(@"<  %s", __cmd);
}

- (void)phase1RegisterStructure:(CDType *)structure;
{
    if (structure.type == '{') {
        [structureTable phase1RegisterStructure:structure];
    } else if (structure.type == '(') {
        [unionTable phase1RegisterStructure:structure];
    } else {
        NSLog(@"%s, unknown structure type: %d", __cmd, structure.type);
    }
}

#pragma mark - Phase 2

- (void)startPhase2;
{
    NSUInteger maxDepth = structureTable.phase1_maxDepth;
    if (maxDepth < unionTable.phase1_maxDepth)
        maxDepth = unionTable.phase1_maxDepth;

    if (debug) NSLog(@"max structure/union depth is: %lu", maxDepth);

    for (NSUInteger depth = 1; depth <= maxDepth; depth++) {
        [structureTable phase2AtDepth:depth typeController:self];
        [unionTable     phase2AtDepth:depth typeController:self];
    }

    //[structureTable logPhase2Info];
    [structureTable finishPhase2];
    [unionTable     finishPhase2];
}

- (void)startPhase3;
{
    // do phase2 merge on all the types from phase 0
    [structureTable phase2ReplacementOnPhase0WithTypeController:self];
    [unionTable     phase2ReplacementOnPhase0WithTypeController:self];

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
    [unionTable     buildPhase3Exceptions];

    [structureTable phase3WithTypeController:self];
    [unionTable     phase3WithTypeController:self];

    [structureTable finishPhase3];
    [unionTable     finishPhase3];
    //[structureTable logPhase3Info];

    // - All named structures (minus exceptions like struct _flags) get declared at the top level
    // - All anonymous structures (minus exceptions) referenced by a method
    //                                            OR references >1 time gets typedef'd at the top and referenced by typedef subsequently
    // Celebrate!

    // Then... what do we do when printing ivars/method types?
    // CDTypeController - (BOOL)shouldExpandType:(CDType *)type;
    // CDTypeController - (NSString *)typedefNameForType:(CDType *)type;

    //NSLog(@"<  %s", __cmd);
}

- (CDType *)phase2ReplacementForType:(CDType *)type;
{
    if (type.type == '{') return [structureTable phase2ReplacementForType:type];
    if (type.type == '(') return [unionTable     phase2ReplacementForType:type];

    return nil;
}

- (void)phase3RegisterStructure:(CDType *)structure;
{
    //NSLog(@"%s, type= %@", __cmd, [aStructure typeString]);
    if (structure.type == '{') [structureTable phase3RegisterStructure:structure count:1 usedInMethod:NO typeController:self];
    if (structure.type == '(') [unionTable     phase3RegisterStructure:structure count:1 usedInMethod:NO typeController:self];
}

- (CDType *)phase3ReplacementForType:(CDType *)type;
{
    if (type.type == '{') return [structureTable phase3ReplacementForType:type];
    if (type.type == '(') return [unionTable     phase3ReplacementForType:type];

    return nil;
}

#pragma mark -

- (BOOL)shouldShowName:(NSString *)name;
{
    return (self.classDump.shouldMatchRegex == NO) || [self.classDump regexMatchesString:name];
}

- (BOOL)shouldExpandType:(CDType *)type;
{
    if (type.type == '{') return [structureTable shouldExpandType:type];
    if (type.type == '(') return [unionTable     shouldExpandType:type];

    return NO;
}

- (NSString *)typedefNameForType:(CDType *)type;
{
    if (type.type == '{') return [structureTable typedefNameForType:type];
    if (type.type == '(') return [unionTable     typedefNameForType:type];

    return nil;
}

@end
