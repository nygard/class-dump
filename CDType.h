// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

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

- (CDType *)subtype;
- (CDTypeName *)typeName;

- (NSArray *)members;
//- (void)setMembers:(NSArray *)newMembers;

- (int)typeIgnoringModifiers;

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

- (void)phase:(NSUInteger)phase registerTypesWithObject:(CDTypeController *)typeController ivar:(BOOL)isIvar;
- (void)phase0RegisterStructuresWithObject:(CDTypeController *)typeController ivar:(BOOL)isIvar;
- (void)phase1RegisterStructuresWithObject:(CDTypeController *)typeController;

- (BOOL)isEqual:(CDType *)otherType;
- (BOOL)isBasicallyEqual:(CDType *)otherType;
- (BOOL)isStructureEqual:(CDType *)otherType;

- (BOOL)canMergeWithType:(CDType *)otherType;
- (void)mergeWithType:(CDType *)otherType;
- (void)_recursivelyMergeWithType:(CDType *)otherType;

- (void)generateMemberNames;
- (NSUInteger)structureDepth;

- (id)copyWithZone:(NSZone *)zone;

- (void)phase2MergeWithTypeController:(CDTypeController *)typeController;

- (void)phase3WithTypeController:(CDTypeController *)typeController;

@end
