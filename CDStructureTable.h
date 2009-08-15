// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDClassDump, CDType, CDSymbolReferences, CDTypeController, CDTypeFormatter;

@interface CDStructureTable : NSObject
{
    NSString *identifier;
    NSString *anonymousBaseName;

    // Phase 0 - top level
    NSMutableDictionary *phase0_ivar_structureInfo; // key: NSString (typeString), value: CDStructureInfo
    NSMutableDictionary *phase0_method_structureInfo; // key: NSString (typeString), value: CDStructureInfo

    // Phase 1 - all substructures
    NSMutableDictionary *phase1_structureInfo; // key: NSString (typeString), value: CDStructureInfo
    NSUInteger phase1_maxDepth;
    NSMutableDictionary *phase1_groupedByDepth; // key: NSNumber (structureDepth), value: NSMutableArray of CDStructureInfo

    // Phase 2 - merging all structure bottom up
    NSMutableDictionary *phase2_namedStructureInfo; // key: NSString (name), value: CDStructureInfo
    NSMutableDictionary *phase2_anonStructureInfo; // key: NSString (reallyBareTypeString), value: CDStructureInfo
    NSMutableArray *phase2_nameExceptions; // Of CDStructureInfo
    NSMutableArray *phase2_anonExceptions; // Of CDStructureInfo

    struct {
        unsigned int shouldDebug:1;
    } flags;
}

- (id)init;
- (void)dealloc;

- (NSString *)identifier;
- (void)setIdentifier:(NSString *)newIdentifier;

- (NSString *)anonymousBaseName;
- (void)setAnonymousBaseName:(NSString *)newName;

- (BOOL)shouldDebug;
- (void)setShouldDebug:(BOOL)newFlag;

- (void)generateNamesForAnonymousStructures;

- (void)appendNamedStructuresToString:(NSMutableString *)resultString
                            formatter:(CDTypeFormatter *)aTypeFormatter
                     symbolReferences:(CDSymbolReferences *)symbolReferences;

- (void)appendTypedefsToString:(NSMutableString *)resultString
                     formatter:(CDTypeFormatter *)aTypeFormatter
              symbolReferences:(CDSymbolReferences *)symbolReferences;

- (CDType *)replacementForType:(CDType *)aType;
- (NSString *)typedefNameForStructureType:(CDType *)aType;


- (void)phase0RegisterStructure:(CDType *)aStructure ivar:(BOOL)isIvar;
- (void)finishPhase0;

- (void)generateMemberNames;

- (void)phase1WithTypeController:(CDTypeController *)typeController;
- (void)phase1RegisterStructure:(CDType *)aStructure;
- (void)finishPhase1;
- (NSUInteger)phase1_maxDepth;

- (void)phase2AtDepth:(NSUInteger)depth typeController:(CDTypeController *)typeController;
- (CDType *)phase2ReplacementForType:(CDType *)type;

- (void)mergePhase1StructuresAtDepth:(NSUInteger)depth;
- (void)logPhase2Info;

@end
