// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDClassDump, CDType, CDStructureInfo, CDSymbolReferences, CDTypeController, CDTypeFormatter;

enum {
    CDTableTypeStructure = 0,
    CDTableTypeUnion = 1,
};
typedef NSUInteger CDTableType;

@interface CDStructureTable : NSObject
{
    NSString *identifier;
    NSString *anonymousBaseName;

    // Phase 0 - top level
    NSMutableDictionary *phase0_structureInfo; // key: NSString (typeString), value: CDStructureInfo

    // Phase 1 - all substructures
    NSMutableDictionary *phase1_structureInfo; // key: NSString (typeString), value: CDStructureInfo
    NSUInteger phase1_maxDepth;
    NSMutableDictionary *phase1_groupedByDepth; // key: NSNumber (structureDepth), value: NSMutableArray of CDStructureInfo

    // Phase 2 - merging all structure bottom up
    NSMutableDictionary *phase2_namedStructureInfo; // key: NSString (name), value: CDStructureInfo
    NSMutableDictionary *phase2_anonStructureInfo; // key: NSString (reallyBareTypeString), value: CDStructureInfo
    NSMutableArray *phase2_nameExceptions; // Of CDStructureInfo
    NSMutableArray *phase2_anonExceptions; // Of CDStructureInfo

    // Phase 3 - merged reference counts from updated phase0 types
    NSMutableDictionary *phase3_namedStructureInfo; // key: NSString (name), value: CDStructureInfo
    NSMutableDictionary *phase3_anonStructureInfo; // key: NSString (reallyBareTypeString), value: CDStructureInfo

    NSMutableDictionary *phase3_nameExceptions; // key: NSString (typeString), value: CDStructureInfo
    NSMutableDictionary *phase3_anonExceptions; // key: NSString (typeString), value: CDStructureInfo

    NSMutableSet *phase3_exceptionalNames; // Of NSString
    NSMutableSet *phase3_inMethodNameExceptions; // Of NSString

    struct {
        unsigned int shouldDebug:1;
    } flags;

    NSMutableSet *debugNames; // NSString (name)
    NSMutableSet *debugAnon; // NSString (reallyBareTypeString)
}

- (id)init;
- (void)dealloc;

- (NSString *)identifier;
- (void)setIdentifier:(NSString *)newIdentifier;

- (NSString *)anonymousBaseName;
- (void)setAnonymousBaseName:(NSString *)newName;

- (BOOL)shouldDebug;
- (void)setShouldDebug:(BOOL)newFlag;

// Phase 0
- (void)phase0RegisterStructure:(CDType *)aStructure usedInMethod:(BOOL)isUsedInMethod;
- (void)finishPhase0;
- (void)logPhase0Info;

// Phase 1
- (void)phase1WithTypeController:(CDTypeController *)typeController;
- (void)phase1RegisterStructure:(CDType *)aStructure;
- (void)finishPhase1;
- (NSUInteger)phase1_maxDepth;

// Phase 2
- (void)phase2AtDepth:(NSUInteger)depth typeController:(CDTypeController *)typeController;
- (CDType *)phase2ReplacementForType:(CDType *)type;

- (void)finishPhase2;
- (void)logPhase2Info;

// Phase 3
- (void)phase2ReplacementOnPhase0WithTypeController:(CDTypeController *)typeController;

- (void)buildPhase3Exceptions;
- (void)phase3WithTypeController:(CDTypeController *)typeController;
- (void)phase3RegisterStructure:(CDType *)aStructure
                          count:(NSUInteger)referenceCount
                   usedInMethod:(BOOL)isUsedInMethod
                 typeController:(CDTypeController *)typeController;
- (void)finishPhase3;
- (void)logPhase3Info;
- (CDType *)phase3ReplacementForType:(CDType *)type;

// Other

- (void)appendNamedStructuresToString:(NSMutableString *)resultString
                            formatter:(CDTypeFormatter *)aTypeFormatter
                     symbolReferences:(CDSymbolReferences *)symbolReferences
                             markName:(NSString *)markName;

- (void)appendTypedefsToString:(NSMutableString *)resultString
                     formatter:(CDTypeFormatter *)aTypeFormatter
              symbolReferences:(CDSymbolReferences *)symbolReferences
                      markName:(NSString *)markName;

- (void)generateTypedefNames;
- (void)generateMemberNames;

- (BOOL)shouldExpandStructureInfo:(CDStructureInfo *)info;
- (BOOL)shouldExpandType:(CDType *)type;
- (NSString *)typedefNameForType:(CDType *)type;

- (void)debugName:(NSString *)name;
- (void)debugAnon:(NSString *)str;

@end
