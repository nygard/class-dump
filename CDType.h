// This file is part of APPNAME, SHORT DESCRIPTION
// Copyright (C) 2003 Steve Nygard.  All rights reserved.

#import <Foundation/NSObject.h>
#import "CDStructRegistrationProtocol.h"

@class NSArray, NSString;
@class CDTypeFormatter;

@interface CDType : NSObject
{
    int type;
    CDType *subtype;
    NSString *typeName; // Class name? + bitfield size, array size
    NSArray *members;
    NSString *bitfieldSize;
    NSString *arraySize;

    NSString *variableName;
}

- (id)init;
- (id)initSimpleType:(int)aTypeCode;
- (id)initIDType:(NSString *)aName;
- (id)initNamedType:(NSString *)aName;
- (id)initStructType:(NSString *)aName members:(NSArray *)someMembers;
- (id)initUnionType:(NSString *)aName members:(NSArray *)someMembers;
- (id)initBitfieldType:(NSString *)aBitfieldSize;
- (id)initArrayType:(CDType *)aType count:(NSString *)aCount;
- (id)initPointerType:(CDType *)aType;
- (id)initModifier:(int)aModifier type:(CDType *)aType;
- (void)dealloc;

- (NSString *)variableName;
- (void)setVariableName:(NSString *)newVariableName;

- (int)type;
- (BOOL)isIDType;

- (CDType *)subtype;
- (NSString *)typeName;
- (NSArray *)members;

- (int)typeIgnoringModifiers;

- (NSString *)description;

- (NSString *)formattedString:(NSString *)previousName formatter:(CDTypeFormatter *)typeFormatter level:(int)level;
- (NSString *)formattedStringForMembersAtLevel:(int)level formatter:(CDTypeFormatter *)typeFormatter;
- (NSString *)formattedStringForSimpleType;

- (NSString *)typeString;
- (NSString *)bareTypeString;
- (NSString *)_typeStringWithVariableNames:(BOOL)shouldUseVariableNames;
- (NSString *)_typeStringForMembersWithVariableNames:(BOOL)shouldUseVariableNames;

- (void)registerStructsWithObject:(id <CDStructRegistration>)anObject;

- (BOOL)isEqual:(CDType *)otherType;
- (BOOL)isStructureEqual:(CDType *)otherType;
- (int)namedMemberCount;

- (void)mergeWithType:(CDType *)otherType;

@end
