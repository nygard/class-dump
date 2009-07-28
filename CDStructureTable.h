// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import <Foundation/Foundation.h>

#import "CDStructureRegistrationProtocol.h"

@class CDClassDump, CDType, CDSymbolReferences, CDTypeFormatter;

@interface CDStructureTable : NSObject
{
    NSString *identifier;
    NSString *anonymousBaseName;

    NSMutableDictionary *structuresByName;
    NSMutableDictionary *anonymousStructureCountsByType;
    NSMutableDictionary *anonymousStructuresByType;
    NSMutableDictionary *anonymousStructureNamesByType;

    NSMutableSet *forcedTypedefs;

    NSMutableDictionary *keyTypeStringsByBareTypeStrings; // Phase 1.  Keyed on -bareTypeString.  Values are mutable sets of the keyTypeStrings.
    NSMutableDictionary *replacementSignatures; // generated at end of phase 1.  Maps bareTypeStrings to keyTypeStrings.

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

- (void)logPhase1Data;
- (void)finishPhase1;
- (void)logInfo;

- (void)generateNamesForAnonymousStructures;

- (void)appendNamedStructuresToString:(NSMutableString *)resultString classDump:(CDClassDump *)aClassDump formatter:(CDTypeFormatter *)aTypeFormatter symbolReferences:(CDSymbolReferences *)symbolReferences;
- (void)appendTypedefsToString:(NSMutableString *)resultString classDump:(CDClassDump *)aClassDump formatter:(CDTypeFormatter *)aTypeFormatter symbolReferences:(CDSymbolReferences *)symbolReferences;

- (void)forceTypedefForStructure:(NSString *)typeString;
- (CDType *)replacementForType:(CDType *)aType;
- (NSString *)typedefNameForStructureType:(CDType *)aType;

- (void)phase1RegisterStructure:(CDType *)aStructure;
- (BOOL)phase2RegisterStructure:(CDType *)aStructure withObject:(id <CDStructureRegistration>)anObject usedInMethod:(BOOL)isUsedInMethod
                countReferences:(BOOL)shouldCountReferences;

- (void)generateMemberNames;

@end
