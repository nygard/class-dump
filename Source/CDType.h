// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

@class CDTypeController, CDTypeFormatter, CDTypeName;

@interface CDType : NSObject <NSCopying>

- (id)initSimpleType:(int)type;
- (id)initIDType:(CDTypeName *)name;
- (id)initIDType:(CDTypeName *)name withProtocols:(NSArray *)protocols;
- (id)initIDTypeWithProtocols:(NSArray *)protocols;
- (id)initStructType:(CDTypeName *)name members:(NSArray *)members;
- (id)initUnionType:(CDTypeName *)name members:(NSArray *)members;
- (id)initBitfieldType:(NSString *)bitfieldSize;
- (id)initArrayType:(CDType *)type count:(NSString *)count;
- (id)initPointerType:(CDType *)type;
- (id)initFunctionPointerType;
- (id)initBlockTypeWithTypes:(NSArray *)types;
- (id)initModifier:(int)modifier type:(CDType *)type;

@property (strong) NSString *variableName;

@property (nonatomic, readonly) int primitiveType;
@property (nonatomic, readonly) BOOL isIDType;
@property (nonatomic, readonly) BOOL isNamedObject;
@property (nonatomic, readonly) BOOL isTemplateType;

@property (nonatomic, readonly) CDType *subtype;
@property (nonatomic, readonly) CDTypeName *typeName;

@property (nonatomic, readonly) NSArray *members;
@property (nonatomic, readonly) NSArray *types;

@property (nonatomic, readonly) int typeIgnoringModifiers;
@property (nonatomic, readonly) NSUInteger structureDepth;

- (NSString *)formattedString:(NSString *)previousName formatter:(CDTypeFormatter *)typeFormatter level:(NSUInteger)level;

@property (nonatomic, readonly) NSString *typeString;
@property (nonatomic, readonly) NSString *bareTypeString;
@property (nonatomic, readonly) NSString *reallyBareTypeString;
@property (nonatomic, readonly) NSString *keyTypeString;


- (BOOL)canMergeWithType:(CDType *)otherType;
- (void)mergeWithType:(CDType *)otherType;

@property (nonatomic, readonly) NSArray *memberVariableNames;
- (void)generateMemberNames;

// Phase 0
- (void)phase:(NSUInteger)phase registerTypesWithObject:(CDTypeController *)typeController usedInMethod:(BOOL)isUsedInMethod;
- (void)phase0RecursivelyFixStructureNames:(BOOL)flag;

// Phase 1
- (void)phase1RegisterStructuresWithObject:(CDTypeController *)typeController;

// Phase 2
- (void)phase2MergeWithTypeController:(CDTypeController *)typeController debug:(BOOL)phase2Debug;

// Phase 3
- (void)phase3RegisterMembersWithTypeController:(CDTypeController *)typeController;
- (void)phase3MergeWithTypeController:(CDTypeController *)typeController;

@end
