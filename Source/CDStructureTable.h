// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDClassDump, CDType, CDStructureInfo, CDSymbolReferences, CDTypeController, CDTypeFormatter;

enum {
    CDTableType_Structure = 0,
    CDTableType_Union = 1,
};
typedef NSUInteger CDTableType;

@interface CDStructureTable : NSObject

@property (retain) NSString *identifier;
@property (retain) NSString *anonymousBaseName;
@property (assign) BOOL shouldDebug;

// Phase 0
- (void)phase0RegisterStructure:(CDType *)aStructure usedInMethod:(BOOL)isUsedInMethod;
- (void)finishPhase0;
- (void)logPhase0Info;

// Phase 1
- (void)phase1WithTypeController:(CDTypeController *)typeController;
- (void)phase1RegisterStructure:(CDType *)aStructure;
- (void)finishPhase1;
@property (nonatomic, readonly) NSUInteger phase1_maxDepth;

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
