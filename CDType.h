// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDSymbolReferences, CDTypeController, CDTypeFormatter, CDTypeName;

@interface CDType : NSObject <NSCopying>
{
    int type;
    NSArray *protocols;
    CDType *subtype;
    CDTypeName *typeName;
    NSMutableArray *members;
    NSString *bitfieldSize;
    NSString *arraySize;

    NSString *variableName;
}

- (id)init;
- (id)initSimpleType:(int)aTypeCode;
- (id)initIDType:(CDTypeName *)aName;
- (id)initIDTypeWithProtocols:(NSArray *)someProtocols;
- (id)initStructType:(CDTypeName *)aName members:(NSArray *)someMembers;
- (id)initUnionType:(CDTypeName *)aName members:(NSArray *)someMembers;
- (id)initBitfieldType:(NSString *)aBitfieldSize;
- (id)initArrayType:(CDType *)aType count:(NSString *)aCount;
- (id)initPointerType:(CDType *)aType;
- (id)initModifier:(int)aModifier type:(CDType *)aType;
- (void)dealloc;

@property(retain) NSString *variableName;

- (int)type;
- (BOOL)isIDType;
- (BOOL)isNamedObject;
- (BOOL)isTemplateType;

- (CDType *)subtype;
- (CDTypeName *)typeName;

- (NSArray *)members;

- (int)typeIgnoringModifiers;
- (NSUInteger)structureDepth;

- (NSString *)description;

- (NSString *)formattedString:(NSString *)previousName formatter:(CDTypeFormatter *)typeFormatter level:(NSUInteger)level symbolReferences:(CDSymbolReferences *)symbolReferences;
- (NSString *)formattedStringForMembersAtLevel:(NSUInteger)level formatter:(CDTypeFormatter *)typeFormatter symbolReferences:(CDSymbolReferences *)symbolReferences;
- (NSString *)formattedStringForSimpleType;

- (NSString *)typeString;
- (NSString *)bareTypeString;
- (NSString *)reallyBareTypeString;
- (NSString *)keyTypeString;
- (NSString *)_typeStringWithVariableNamesToLevel:(NSUInteger)level showObjectTypes:(BOOL)shouldShowObjectTypes;
- (NSString *)_typeStringForMembersWithVariableNamesToLevel:(NSInteger)level showObjectTypes:(BOOL)shouldShowObjectTypes;

- (BOOL)isEqual:(CDType *)otherType;
- (id)copyWithZone:(NSZone *)zone;

- (BOOL)canMergeWithType:(CDType *)otherType;
- (void)mergeWithType:(CDType *)otherType;
- (void)_recursivelyMergeWithType:(CDType *)otherType;

- (void)generateMemberNames;

// Phase 0
- (void)phase:(NSUInteger)phase registerTypesWithObject:(CDTypeController *)typeController usedInMethod:(BOOL)isUsedInMethod;
- (void)phase0RegisterStructuresWithObject:(CDTypeController *)typeController usedInMethod:(BOOL)isUsedInMethod;
- (void)phase0RecursivelyFixStructureNames:(BOOL)flag;

// Phase 1
- (void)phase1RegisterStructuresWithObject:(CDTypeController *)typeController;

// Phase 2
- (void)phase2MergeWithTypeController:(CDTypeController *)typeController debug:(BOOL)phase2Debug;
- (void)_phase2MergeWithTypeController:(CDTypeController *)typeController debug:(BOOL)phase2Debug;

// Phase 3
- (void)phase3RegisterWithTypeController:(CDTypeController *)typeController;
- (void)phase3RegisterMembersWithTypeController:(CDTypeController *)typeController;
- (void)phase3MergeWithTypeController:(CDTypeController *)typeController;

@end
