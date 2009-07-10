// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import <Foundation/Foundation.h>

#import "CDStructureRegistrationProtocol.h"

@class CDClassDump, CDSymbolReferences;
@class CDVisitor;
@class CDOCMethod, CDOCProperty;

@interface CDOCProtocol : NSObject
{
    NSString *name;
    NSMutableArray *protocols;
    NSMutableArray *classMethods;
    NSMutableArray *instanceMethods;
    NSMutableArray *optionalClassMethods;
    NSMutableArray *optionalInstanceMethods;
    NSMutableArray *properties;

    NSMutableSet *adoptedProtocolNames;
}

- (id)init;
- (void)dealloc;

- (NSString *)name;
- (void)setName:(NSString *)newName;

- (NSArray *)protocols;
- (void)addProtocol:(CDOCProtocol *)aProtocol;
- (void)removeProtocol:(CDOCProtocol *)aProtocol;

- (NSArray *)classMethods;
- (void)addClassMethod:(CDOCMethod *)method;

- (NSArray *)instanceMethods;
- (void)addInstanceMethod:(CDOCMethod *)method;

- (NSArray *)optionalClassMethods;
- (void)addOptionalClassMethod:(CDOCMethod *)method;

- (NSArray *)optionalInstanceMethods;
- (void)addOptionalInstanceMethod:(CDOCMethod *)method;

- (NSArray *)properties;
- (void)addProperty:(CDOCProperty *)property;

- (BOOL)hasMethods;

- (NSString *)description;
- (void)registerStructuresWithObject:(id <CDStructureRegistration>)anObject phase:(NSUInteger)phase;
- (void)registerStructuresFromMethods:(NSArray *)methods withObject:(id <CDStructureRegistration>)anObject phase:(NSUInteger)phase;
- (void)registerStructuresFromMethodTypes:(NSArray *)methodTypes withObject:(id <CDStructureRegistration>)anObject phase:(NSUInteger)phase;

- (NSString *)sortableName;
- (NSComparisonResult)ascendingCompareByName:(CDOCProtocol *)otherProtocol;

- (NSString *)findTag:(CDSymbolReferences *)symbolReferences;

- (void)recursivelyVisit:(CDVisitor *)aVisitor;
- (void)recursivelyVisitMethods:(CDVisitor *)aVisitor;
- (void)visitProperties:(CDVisitor *)aVisitor;

@end
