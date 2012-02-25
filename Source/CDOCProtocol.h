// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDSymbolReferences, CDTypeController;
@class CDVisitor, CDVisitorPropertyState;
@class CDOCMethod, CDOCProperty;

@interface CDOCProtocol : NSObject

@property (strong) NSString *name;

@property (readonly) NSArray *protocols;
- (void)addProtocol:(CDOCProtocol *)protocol;
- (void)removeProtocol:(CDOCProtocol *)protocol;

- (NSArray *)classMethods;
- (void)addClassMethod:(CDOCMethod *)method;

- (NSArray *)instanceMethods;
- (void)addInstanceMethod:(CDOCMethod *)method;

- (NSArray *)optionalClassMethods;
- (void)addOptionalClassMethod:(CDOCMethod *)method;

- (NSArray *)optionalInstanceMethods;
- (void)addOptionalInstanceMethod:(CDOCMethod *)method;

@property (readonly) NSArray *properties;
- (void)addProperty:(CDOCProperty *)property;

@property (nonatomic, readonly) BOOL hasMethods;

- (void)registerTypesWithObject:(CDTypeController *)typeController phase:(NSUInteger)phase;
- (void)registerTypesFromMethods:(NSArray *)methods withObject:(CDTypeController *)typeController phase:(NSUInteger)phase;

- (NSComparisonResult)ascendingCompareByName:(CDOCProtocol *)otherProtocol;

- (NSString *)findTag:(CDSymbolReferences *)symbolReferences;

- (void)visitMethods:(CDVisitor *)visitor propertyState:(CDVisitorPropertyState *)propertyState;

@end
