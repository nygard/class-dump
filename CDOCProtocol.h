//
// $Id: CDOCProtocol.h,v 1.16 2004/02/02 21:37:20 nygard Exp $
//

//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import <Foundation/NSObject.h>

#import "CDStructureRegistrationProtocol.h"

@class NSArray, NSMutableArray, NSMutableSet, NSMutableString, NSString;
@class CDClassDump2, CDSymbolReferences;

@interface CDOCProtocol : NSObject
{
    NSString *name;
    NSMutableArray *protocols;
    NSArray *classMethods;
    NSArray *instanceMethods;

    NSMutableSet *adoptedProtocolNames;
}

- (id)init;
- (void)dealloc;

- (NSString *)name;
- (void)setName:(NSString *)newName;

- (NSArray *)protocols;
- (void)addProtocol:(CDOCProtocol *)aProtocol;
- (void)removeProtocol:(CDOCProtocol *)aProtocol;
- (void)addProtocolsFromArray:(NSArray *)newProtocols;

- (NSArray *)classMethods;
- (void)setClassMethods:(NSArray *)newClassMethods;

- (NSArray *)instanceMethods;
- (void)setInstanceMethods:(NSArray *)newInstanceMethods;

- (NSString *)description;
- (void)appendToString:(NSMutableString *)resultString classDump:(CDClassDump2 *)aClassDump symbolReferences:(CDSymbolReferences *)symbolReferences;
- (void)appendMethodsToString:(NSMutableString *)resultString classDump:(CDClassDump2 *)aClassDump symbolReferences:(CDSymbolReferences *)symbolReferences;
- (void)registerStructuresWithObject:(id <CDStructureRegistration>)anObject phase:(int)phase;
- (void)registerStructuresFromMethods:(NSArray *)methods withObject:(id <CDStructureRegistration>)anObject phase:(int)phase;
- (void)registerStructuresFromMethodTypes:(NSArray *)methodTypes withObject:(id <CDStructureRegistration>)anObject phase:(int)phase;

- (NSString *)sortableName;
- (NSComparisonResult)ascendingCompareByName:(CDOCProtocol *)otherProtocol;

@end
