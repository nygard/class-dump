//
// $Id: CDStructureTable.h,v 1.2 2004/01/08 06:10:11 nygard Exp $
//

//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import <Foundation/NSObject.h>

#import "CDStructRegistrationProtocol.h"

@class NSMutableDictionary, NSMutableSet, NSMutableString;
@class CDType, CDTypeFormatter;

@interface CDStructureTable : NSObject <CDStructRegistration>
{
    NSMutableDictionary *structuresByName;

    NSMutableDictionary *anonymousStructureCountsByType;
    NSMutableDictionary *anonymousStructuresByType;
    NSMutableDictionary *anonymousStructureNamesByType;

    NSMutableDictionary *replacementTypes;
    NSMutableSet *forcedTypedefs;

    NSString *anonymousBaseName;
}

- (id)init;
- (void)dealloc;

- (NSString *)anonymousBaseName;
- (void)setAnonymousBaseName:(NSString *)newName;

- (void)doneRegistration;

- (void)logStructureCounts;
- (void)logReplacementTypes;
- (void)logNamedStructures;
- (void)logAnonymousStructures;

- (void)processIsomorphicStructures;
- (void)replaceTypeString:(NSString *)originalTypeString withTypeString:(NSString *)replacementTypeString;

- (void)generateNamesForAnonymousStructures;

- (void)appendNamedStructuresToString:(NSMutableString *)resultString formatter:(CDTypeFormatter *)aTypeFormatter;
- (void)appendTypedefsToString:(NSMutableString *)resultString formatter:(CDTypeFormatter *)aTypeFormatter;

- (void)forceTypedefForStructure:(NSString *)typeString;
- (CDType *)replacementForType:(CDType *)aType;
- (NSString *)typedefNameForStructureType:(CDType *)aType;

- (void)registerStruct:(CDType *)structType name:(NSString *)aName usedInMethod:(BOOL)isUsedInMethod countReferences:(BOOL)shouldCountReferences;

@end
