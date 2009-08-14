// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDClassDump, CDStructureTable, CDSymbolReferences, CDType, CDTypeFormatter;

@interface CDTypeController : NSObject
{
    CDClassDump *classDump; // passed during formatting, to get at options.

    CDTypeFormatter *ivarTypeFormatter;
    CDTypeFormatter *methodTypeFormatter;
    CDTypeFormatter *propertyTypeFormatter;
    CDTypeFormatter *structDeclarationTypeFormatter;

    CDStructureTable *structureTable;
    CDStructureTable *unionTable;
}

- (id)init;
- (void)dealloc;

@property(retain) CDClassDump *classDump; // TODO: retain loop.

@property(readonly) CDTypeFormatter *ivarTypeFormatter;
@property(readonly) CDTypeFormatter *methodTypeFormatter;
@property(readonly) CDTypeFormatter *propertyTypeFormatter;
@property(readonly) CDTypeFormatter *structDeclarationTypeFormatter;

- (CDType *)typeFormatter:(CDTypeFormatter *)aFormatter replacementForType:(CDType *)aType;
- (NSString *)typeFormatter:(CDTypeFormatter *)aFormatter typedefNameForStruct:(CDType *)structType level:(NSUInteger)level;

- (void)endPhase:(NSUInteger)phase;

- (void)appendStructuresToString:(NSMutableString *)resultString symbolReferences:(CDSymbolReferences *)symbolReferences;

- (void)generateMemberNames;

- (void)phase0RegisterStructure:(CDType *)aStructure ivar:(BOOL)isIvar;
- (void)phase1RegisterStructure:(CDType *)aStructure;

- (void)startPhase1;

- (BOOL)shouldShowName:(NSString *)name;

@end
