// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

@protocol CDTypeControllerDelegate;

@class CDClassDump, CDType, CDTypeFormatter;

@interface CDTypeController : NSObject

- (id)initWithClassDump:(CDClassDump *)classDump;

@property (weak) id <CDTypeControllerDelegate> delegate;

@property (readonly) CDTypeFormatter *ivarTypeFormatter;
@property (readonly) CDTypeFormatter *methodTypeFormatter;
@property (readonly) CDTypeFormatter *propertyTypeFormatter;
@property (readonly) CDTypeFormatter *structDeclarationTypeFormatter;

@property (nonatomic, readonly) BOOL shouldShowIvarOffsets;
@property (nonatomic, readonly) BOOL shouldShowMethodAddresses;
@property (nonatomic, readonly) BOOL targetArchUses64BitABI;

@property (nonatomic, assign) BOOL hasUnknownFunctionPointers;
@property (nonatomic, assign) BOOL hasUnknownBlocks;

- (CDType *)typeFormatter:(CDTypeFormatter *)typeFormatter replacementForType:(CDType *)type;
- (NSString *)typeFormatter:(CDTypeFormatter *)typeFormatter typedefNameForStructure:(CDType *)structureType level:(NSUInteger)level;
- (void)typeFormatter:(CDTypeFormatter *)typeFormatter didReferenceClassName:(NSString *)name;
- (void)typeFormatter:(CDTypeFormatter *)typeFormatter didReferenceProtocolNames:(NSArray *)names;

- (void)appendStructuresToString:(NSMutableString *)resultString;

// Phase 0 - initiated from -[CDClassDump registerTypes]
- (void)phase0RegisterStructure:(CDType *)structure usedInMethod:(BOOL)isUsedInMethod;

// Run phase 1+
- (void)workSomeMagic;

// Phase 1
- (void)phase1RegisterStructure:(CDType *)structure;

- (void)endPhase:(NSUInteger)phase;

- (CDType *)phase2ReplacementForType:(CDType *)type;

- (void)phase3RegisterStructure:(CDType *)structure;
- (CDType *)phase3ReplacementForType:(CDType *)type;

- (BOOL)shouldShowName:(NSString *)name;
- (BOOL)shouldExpandType:(CDType *)type;
- (NSString *)typedefNameForType:(CDType *)type;

@end

#pragma mark -

@protocol CDTypeControllerDelegate <NSObject>
@optional
- (void)typeController:(CDTypeController *)typeController didReferenceClassName:(NSString *)name;
- (void)typeController:(CDTypeController *)typeController didReferenceProtocolNames:(NSArray *)names;
@end
