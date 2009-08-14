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
    NSMutableDictionary *topLevelIvarStructureInfo; // key: NSString (typeString), value: CDStructureInfo
    NSMutableDictionary *topLevelMethodStructureInfo; // key: NSString (typeString), value: CDStructureInfo

    // Phase 1
    NSMutableDictionary *phase1NamedStructureInfo; // key: NSString (typeString), value: CDStructureInfo
    NSMutableDictionary *phase1AnonStructureInfo; // key: NSString (typeString), value: CDStructureInfo

    // Phase 2
    // Same name, different types.
    NSMutableDictionary *phase2NamedStructureInfo; // key: NSString (name), value: CDStructureInfo
    NSMutableDictionary *phase2AnonStructureInfo; // key: NSString (typeString), value: CDStructureInfo
    NSMutableDictionary *phase2NameExceptions; // key: NSString (name), value: NSMutableArray of CDStructureInfo
    NSMutableDictionary *phase2AnonExceptions; // key: NSString (), value: NSMutableArray of CDStructureInfo

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

- (void)mergePhase1StructuresAtDepth:(NSUInteger)depth;
- (void)logPhase2Info;

@end
