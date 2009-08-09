// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import <Foundation/Foundation.h>
#import "CDStructureRegistrationProtocol.h"

@class CDSymbolReferences, CDTypeFormatter, CDTypeName;

@interface CDType : NSObject
{
    int type;
    NSArray *protocols;
    CDType *subtype;
    CDTypeName *typeName;
    NSArray *members;
    NSString *bitfieldSize;
    NSString *arraySize;

    NSString *variableName;
}

- (id)init;
- (id)initSimpleType:(int)aTypeCode;
- (id)initIDType:(CDTypeName *)aName;
- (id)initIDTypeWithProtocols:(NSArray *)someProtocols;
- (id)initNamedType:(CDTypeName *)aName;
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

- (CDType *)subtype;
- (CDTypeName *)typeName;

- (NSArray *)members;
- (void)setMembers:(NSArray *)newMembers;

- (int)typeIgnoringModifiers;

- (NSString *)description;

- (NSString *)formattedString:(NSString *)previousName formatter:(CDTypeFormatter *)typeFormatter level:(NSUInteger)level symbolReferences:(CDSymbolReferences *)symbolReferences;
- (NSString *)formattedStringForMembersAtLevel:(NSUInteger)level formatter:(CDTypeFormatter *)typeFormatter symbolReferences:(CDSymbolReferences *)symbolReferences;
- (NSString *)formattedStringForSimpleType;

- (NSString *)typeString;
- (NSString *)bareTypeString;
- (NSString *)keyTypeString;
- (NSString *)_typeStringWithVariableNamesToLevel:(NSUInteger)level;
- (NSString *)_typeStringForMembersWithVariableNamesToLevel:(NSInteger)level;

- (void)phase:(NSUInteger)phase registerStructuresWithObject:(id <CDStructureRegistration>)anObject usedInMethod:(BOOL)isUsedInMethod;
- (void)phase0RegisterStructuresWithObject:(id <CDStructureRegistration>)anObject;
- (void)phase1RegisterStructuresWithObject:(id <CDStructureRegistration>)anObject;
- (void)phase2RegisterStructuresWithObject:(id <CDStructureRegistration>)anObject
                              usedInMethod:(BOOL)isUsedInMethod
                           countReferences:(BOOL)shouldCountReferences;

- (BOOL)isEqual:(CDType *)otherType;
- (BOOL)isBasicallyEqual:(CDType *)otherType;
- (BOOL)isStructureEqual:(CDType *)otherType;

- (BOOL)canMergeWithType:(CDType *)otherType;
- (void)mergeWithType:(CDType *)otherType;

- (void)generateMemberNames;
- (NSUInteger)structureDepth;

@end
