// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDClassDump, CDSymbolReferences, CDTypeController;
@class CDVisitor, CDVisitorPropertyState;
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
- (void)registerTypesWithObject:(CDTypeController *)typeController phase:(NSUInteger)phase;
- (void)registerTypesFromMethods:(NSArray *)methods withObject:(CDTypeController *)typeController phase:(NSUInteger)phase;

- (NSString *)sortableName;
- (NSComparisonResult)ascendingCompareByName:(CDOCProtocol *)otherProtocol;

- (NSString *)findTag:(CDSymbolReferences *)symbolReferences;

- (void)recursivelyVisit:(CDVisitor *)aVisitor;
- (void)visitMethods:(CDVisitor *)aVisitor propertyState:(CDVisitorPropertyState *)propertyState;
- (void)visitProperties:(CDVisitor *)aVisitor;

@end
