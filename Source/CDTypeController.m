// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDTypeController.h"

#import "CDStructureTable.h"
#import "CDClassDump.h"
#import "CDTypeFormatter.h"
#import "CDType.h"

static BOOL debug = NO;

@interface CDTypeController ()
@property (weak, readonly) CDClassDump *classDump;
@property (readonly) CDStructureTable *structureTable;
@property (readonly) CDStructureTable *unionTable;
@end

#pragma mark -

@implementation CDTypeController
{
    __weak CDClassDump *_classDump; // passed during formatting, to get at options.
    __weak id <CDTypeControllerDelegate> _delegate;
    
    CDTypeFormatter *_ivarTypeFormatter;
    CDTypeFormatter *_methodTypeFormatter;
    CDTypeFormatter *_propertyTypeFormatter;
    CDTypeFormatter *_structDeclarationTypeFormatter;
    
    CDStructureTable *_structureTable;
    CDStructureTable *_unionTable;
}

- (id)initWithClassDump:(CDClassDump *)classDump;
{
    if ((self = [super init])) {
        _classDump = classDump;
        
        _ivarTypeFormatter = [[CDTypeFormatter alloc] init];
        _ivarTypeFormatter.shouldExpand = NO;
        _ivarTypeFormatter.shouldAutoExpand = YES;
        _ivarTypeFormatter.baseLevel = 1;
        _ivarTypeFormatter.typeController = self;
        
        _methodTypeFormatter = [[CDTypeFormatter alloc] init];
        _methodTypeFormatter.shouldExpand = NO;
        _methodTypeFormatter.shouldAutoExpand = NO;
        _methodTypeFormatter.baseLevel = 0;
        _methodTypeFormatter.typeController = self;
        
        _propertyTypeFormatter = [[CDTypeFormatter alloc] init];
        _propertyTypeFormatter.shouldExpand = NO;
        _propertyTypeFormatter.shouldAutoExpand = NO;
        _propertyTypeFormatter.baseLevel = 0;
        _propertyTypeFormatter.typeController = self;
        
        _structDeclarationTypeFormatter = [[CDTypeFormatter alloc] init];
        _structDeclarationTypeFormatter.shouldExpand = YES; // But don't expand named struct members...
        _structDeclarationTypeFormatter.shouldAutoExpand = YES;
        _structDeclarationTypeFormatter.baseLevel = 0;
        _structDeclarationTypeFormatter.typeController = self; // But need to ignore some things?
        
        _structureTable = [[CDStructureTable alloc] init];
        _structureTable.anonymousBaseName = @"CDStruct_";
        _structureTable.identifier = @"Structs";
        _structureTable.typeController = self;
        
        _unionTable = [[CDStructureTable alloc] init];
        _unionTable.anonymousBaseName = @"CDUnion_";
        _unionTable.identifier = @"Unions";
        _unionTable.typeController = self;
        
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

- (NSString *)typeFormatter:(CDTypeFormatter *)typeFormatter typedefNameForStructure:(CDType *)structureType level:(NSUInteger)level;
{
    if (level == 0 && typeFormatter == self.structDeclarationTypeFormatter)
        return nil;

    if ([self shouldExpandType:structureType] == NO)
        return [self typedefNameForType:structureType];

    return nil;
}

- (void)typeFormatter:(CDTypeFormatter *)typeFormatter didReferenceClassName:(NSString *)name;
{
    if ([self.delegate respondsToSelector:@selector(typeController:didReferenceClassName:)])
        [self.delegate typeController:self didReferenceClassName:name];
}

- (void)typeFormatter:(CDTypeFormatter *)typeFormatter didReferenceProtocolNames:(NSArray *)names;
{
    if ([self.delegate respondsToSelector:@selector(typeController:didReferenceProtocolNames:)])
        [self.delegate typeController:self didReferenceProtocolNames:names];
}

#pragma mark -

- (void)appendStructuresToString:(NSMutableString *)resultString;
{
    if (self.hasUnknownFunctionPointers && self.hasUnknownBlocks) {
        [resultString appendString:@"#pragma mark Function Pointers and Blocks\n\n"];
    } else if (self.hasUnknownFunctionPointers) {
        [resultString appendString:@"#pragma mark Function Pointers\n\n"];
    } else if (self.hasUnknownBlocks) {
        [resultString appendString:@"#pragma mark Blocks\n\n"];
    }
    
    if (self.hasUnknownFunctionPointers) {
        [resultString appendFormat:@"typedef void (*CDUnknownFunctionPointerType)(void); // return type and parameters are unknown\n\n"];
    }
    
    if (self.hasUnknownBlocks) {
        [resultString appendFormat:@"typedef void (^CDUnknownBlockType)(void); // return type and parameters are unknown\n\n"];
    }
    
    [self.structureTable appendNamedStructuresToString:resultString formatter:self.structDeclarationTypeFormatter markName:@"Named Structures"];
    [self.structureTable appendTypedefsToString:resultString        formatter:self.structDeclarationTypeFormatter markName:@"Typedef'd Structures"];

    [self.unionTable appendNamedStructuresToString:resultString formatter:self.structDeclarationTypeFormatter markName:@"Named Unions"];
    [self.unionTable appendTypedefsToString:resultString        formatter:self.structDeclarationTypeFormatter markName:@"Typedef'd Unions"];
}

// Call this before calling generateMemberNames.
- (void)generateTypedefNames;
{
    [self.structureTable generateTypedefNames];
    [self.unionTable     generateTypedefNames];
}

- (void)generateMemberNames;
{
    [self.structureTable generateMemberNames];
    [self.unionTable     generateMemberNames];
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
        [self.structureTable appendNamedStructuresToString:str formatter:self.structDeclarationTypeFormatter markName:@"Named Structures"];
        [self.unionTable     appendNamedStructuresToString:str formatter:self.structDeclarationTypeFormatter markName:@"Named Unions"];
        [str writeToFile:@"/tmp/out.struct" atomically:NO encoding:NSUTF8StringEncoding error:NULL];

        str = [NSMutableString string];
        [self.structureTable appendTypedefsToString:str formatter:self.structDeclarationTypeFormatter markName:@"Typedef'd Structures"];
        [self.unionTable     appendTypedefsToString:str formatter:self.structDeclarationTypeFormatter markName:@"Typedef'd Unions"];
        [str writeToFile:@"/tmp/out.typedef" atomically:NO encoding:NSUTF8StringEncoding error:NULL];
        //NSLog(@"str =\n%@", str);
    }
}

#pragma mark - Phase 0

- (void)phase0RegisterStructure:(CDType *)structure usedInMethod:(BOOL)isUsedInMethod;
{
    if (structure.primitiveType == '{') {
        [self.structureTable phase0RegisterStructure:structure usedInMethod:isUsedInMethod];
    } else if (structure.primitiveType == '(') {
        [self.unionTable     phase0RegisterStructure:structure usedInMethod:isUsedInMethod];
    } else {
        NSLog(@"%s, unknown structure type: %d", __cmd, structure.primitiveType);
    }
}

- (void)endPhase:(NSUInteger)phase;
{
    if (phase == 0) {
        [self.structureTable finishPhase0];
        [self.unionTable     finishPhase0];
    }
}

#pragma mark - Phase 1

// Phase one builds a list of all of the named and unnamed structures.
// It does this by going through all the top level structures we found in phase 0.
- (void)startPhase1;
{
    //NSLog(@" > %s", __cmd);
    // Structures and unions can be nested, so do phase 1 on each table before finishing the phase.
    [self.structureTable runPhase1];
    [self.unionTable     runPhase1];

    [self.structureTable finishPhase1];
    [self.unionTable     finishPhase1];
    //NSLog(@"<  %s", __cmd);
}

- (void)phase1RegisterStructure:(CDType *)structure;
{
    if (structure.primitiveType == '{') {
        [self.structureTable phase1RegisterStructure:structure];
    } else if (structure.primitiveType == '(') {
        [self.unionTable phase1RegisterStructure:structure];
    } else {
        NSLog(@"%s, unknown structure type: %d", __cmd, structure.primitiveType);
    }
}

#pragma mark - Phase 2

- (void)startPhase2;
{
    NSUInteger maxDepth = self.structureTable.phase1_maxDepth;
    if (maxDepth < self.unionTable.phase1_maxDepth)
        maxDepth = self.unionTable.phase1_maxDepth;

    if (debug) NSLog(@"max structure/union depth is: %lu", maxDepth);

    for (NSUInteger depth = 1; depth <= maxDepth; depth++) {
        [self.structureTable runPhase2AtDepth:depth];
        [self.unionTable     runPhase2AtDepth:depth];
    }

    //[self.structureTable logPhase2Info];
    [self.structureTable finishPhase2];
    [self.unionTable     finishPhase2];
}

- (void)startPhase3;
{
    // do phase2 merge on all the types from phase 0
    [self.structureTable phase2ReplacementOnPhase0];
    [self.unionTable     phase2ReplacementOnPhase0];

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
    [self.structureTable buildPhase3Exceptions];
    [self.unionTable     buildPhase3Exceptions];

    [self.structureTable runPhase3];
    [self.unionTable     runPhase3];

    [self.structureTable finishPhase3];
    [self.unionTable     finishPhase3];
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
    if (type.primitiveType == '{') return [self.structureTable phase2ReplacementForType:type];
    if (type.primitiveType == '(') return [self.unionTable     phase2ReplacementForType:type];

    return nil;
}

- (void)phase3RegisterStructure:(CDType *)structure;
{
    //NSLog(@"%s, type= %@", __cmd, [aStructure typeString]);
    if (structure.primitiveType == '{') [self.structureTable phase3RegisterStructure:structure count:1 usedInMethod:NO];
    if (structure.primitiveType == '(') [self.unionTable     phase3RegisterStructure:structure count:1 usedInMethod:NO];
}

- (CDType *)phase3ReplacementForType:(CDType *)type;
{
    if (type.primitiveType == '{') return [self.structureTable phase3ReplacementForType:type];
    if (type.primitiveType == '(') return [self.unionTable     phase3ReplacementForType:type];

    return nil;
}

#pragma mark -

- (BOOL)shouldShowName:(NSString *)name;
{
    return [self.classDump shouldShowName:name];
}

- (BOOL)shouldExpandType:(CDType *)type;
{
    if (type.primitiveType == '{') return [self.structureTable shouldExpandType:type];
    if (type.primitiveType == '(') return [self.unionTable     shouldExpandType:type];

    return NO;
}

- (NSString *)typedefNameForType:(CDType *)type;
{
    if (type.primitiveType == '{') return [self.structureTable typedefNameForType:type];
    if (type.primitiveType == '(') return [self.unionTable     typedefNameForType:type];

    return nil;
}

@end
