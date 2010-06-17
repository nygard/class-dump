// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDClassDump, CDStructureTable, CDSymbolReferences, CDType, CDTypeFormatter;

@interface CDTypeController : NSObject
{
    CDClassDump *nonretained_classDump; // passed during formatting, to get at options.

    CDTypeFormatter *ivarTypeFormatter;
    CDTypeFormatter *methodTypeFormatter;
    CDTypeFormatter *propertyTypeFormatter;
    CDTypeFormatter *structDeclarationTypeFormatter;

    CDStructureTable *structureTable;
    CDStructureTable *unionTable;
}

- (id)initWithClassDump:(CDClassDump *)aClassDump;
- (void)dealloc;

@property(readonly) CDTypeFormatter *ivarTypeFormatter;
@property(readonly) CDTypeFormatter *methodTypeFormatter;
@property(readonly) CDTypeFormatter *propertyTypeFormatter;
@property(readonly) CDTypeFormatter *structDeclarationTypeFormatter;

- (CDType *)typeFormatter:(CDTypeFormatter *)aFormatter replacementForType:(CDType *)aType;
- (NSString *)typeFormatter:(CDTypeFormatter *)aFormatter typedefNameForStruct:(CDType *)structType level:(NSUInteger)level;

- (void)appendStructuresToString:(NSMutableString *)resultString symbolReferences:(CDSymbolReferences *)symbolReferences;

- (void)generateTypedefNames;
- (void)generateMemberNames;

// Run phase 1+
- (void)workSomeMagic;

// Phase 0
- (void)phase0RegisterStructure:(CDType *)aStructure usedInMethod:(BOOL)isUsedInMethod;
- (void)endPhase:(NSUInteger)phase;

// Phase 1
- (void)startPhase1;
- (void)phase1RegisterStructure:(CDType *)aStructure;

// Phase 2
- (void)startPhase2;

// Phase 3
- (void)startPhase3;

- (BOOL)shouldShowName:(NSString *)name;
- (BOOL)shouldShowIvarOffsets;
- (BOOL)shouldShowMethodAddresses;
- (BOOL)targetArchUses64BitABI;

- (CDType *)phase2ReplacementForType:(CDType *)type;

- (void)phase3RegisterStructure:(CDType *)aStructure;
- (CDType *)phase3ReplacementForType:(CDType *)type;

- (BOOL)shouldExpandType:(CDType *)type;
- (NSString *)typedefNameForType:(CDType *)type;

@end
