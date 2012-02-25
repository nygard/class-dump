// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDClassDump, CDType, CDStructureInfo, CDSymbolReferences, CDTypeController, CDTypeFormatter;

enum {
    CDTableType_Structure = 0,
    CDTableType_Union     = 1,
};
typedef NSUInteger CDTableType;

@interface CDStructureTable : NSObject

@property (retain) NSString *identifier;
@property (retain) NSString *anonymousBaseName;
@property (assign) BOOL shouldDebug;

@property (assign) CDTypeController *typeController;

// Phase 0
- (void)phase0RegisterStructure:(CDType *)structure usedInMethod:(BOOL)isUsedInMethod;
- (void)finishPhase0;

// Phase 1
- (void)phase1WithTypeController:(CDTypeController *)typeController;
- (void)phase1RegisterStructure:(CDType *)structure;
- (void)finishPhase1;
@property (nonatomic, readonly) NSUInteger phase1_maxDepth;

// Phase 2
- (void)phase2AtDepth:(NSUInteger)depth typeController:(CDTypeController *)typeController;
- (CDType *)phase2ReplacementForType:(CDType *)type;

- (void)finishPhase2;

// Phase 3
- (void)phase2ReplacementOnPhase0WithTypeController:(CDTypeController *)typeController;

- (void)buildPhase3Exceptions;
- (void)phase3WithTypeController:(CDTypeController *)typeController;
- (void)phase3RegisterStructure:(CDType *)structure
                          count:(NSUInteger)referenceCount
                   usedInMethod:(BOOL)isUsedInMethod
                 typeController:(CDTypeController *)typeController;
- (void)finishPhase3;
- (CDType *)phase3ReplacementForType:(CDType *)type;

// Other

// Called by CDTypeController prior to calling the next two methods.
- (void)generateTypedefNames;
- (void)generateMemberNames;

// Called by CDTypeController
- (void)appendNamedStructuresToString:(NSMutableString *)resultString
                            formatter:(CDTypeFormatter *)typeFormatter
                     symbolReferences:(CDSymbolReferences *)symbolReferences
                             markName:(NSString *)markName;

// Called by CDTypeController
- (void)appendTypedefsToString:(NSMutableString *)resultString
                     formatter:(CDTypeFormatter *)typeFormatter
              symbolReferences:(CDSymbolReferences *)symbolReferences
                      markName:(NSString *)markName;

- (BOOL)shouldExpandType:(CDType *)type;
- (NSString *)typedefNameForType:(CDType *)type;

// Debugging
- (void)debugName:(NSString *)name;
- (void)debugAnon:(NSString *)str;
- (void)logPhase0Info;
- (void)logPhase2Info;
- (void)logPhase3Info;

@end
