//
// $Id: CDStructureTable.h,v 1.5 2004/01/12 19:07:37 nygard Exp $
//

//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import <Foundation/NSObject.h>

#import "CDStructRegistrationProtocol.h"

@class NSMutableDictionary, NSMutableSet, NSMutableString;
@class CDType, CDTypeFormatter;

@interface CDStructureTable : NSObject
{
    NSMutableDictionary *structuresByName;

    NSMutableDictionary *anonymousStructureCountsByType;
    NSMutableDictionary *anonymousStructuresByType;
    NSMutableDictionary *anonymousStructureNamesByType;

    NSMutableDictionary *replacementTypes;
    NSMutableSet *forcedTypedefs;

    NSString *anonymousBaseName;

    struct {
        unsigned int shouldDebug:1;
    } flags;
}

- (id)init;
- (void)dealloc;

- (NSString *)anonymousBaseName;
- (void)setAnonymousBaseName:(NSString *)newName;

- (BOOL)shouldDebug;
- (void)setShouldDebug:(BOOL)newFlag;

- (void)doneRegistration;

- (void)logStructureCounts;
- (void)logReplacementTypes;
- (void)logNamedStructures;
- (void)logAnonymousStructures;
- (void)logForcedTypedefs;

- (void)processIsomorphicStructures;
- (void)replaceTypeString:(NSString *)originalTypeString withTypeString:(NSString *)replacementTypeString;

- (void)generateNamesForAnonymousStructures;

- (void)appendNamedStructuresToString:(NSMutableString *)resultString formatter:(CDTypeFormatter *)aTypeFormatter;
- (void)appendTypedefsToString:(NSMutableString *)resultString formatter:(CDTypeFormatter *)aTypeFormatter;

- (void)forceTypedefForStructure:(NSString *)typeString;
- (CDType *)replacementForType:(CDType *)aType;
- (NSString *)typedefNameForStructureType:(CDType *)aType;

- (void)registerStructure:(CDType *)structType name:(NSString *)aName withObject:(id <CDStructRegistration>)anObject
             usedInMethod:(BOOL)isUsedInMethod;

@end
