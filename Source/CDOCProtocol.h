// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

@class CDTypeController;
@class CDVisitor, CDVisitorPropertyState;
@class CDOCMethod, CDOCProperty;

@interface CDOCProtocol : NSObject

@property (strong) NSString *name;

@property (readonly) NSArray *protocols;
- (void)addProtocol:(CDOCProtocol *)protocol;
- (void)removeProtocol:(CDOCProtocol *)protocol;
@property (nonatomic, readonly) NSArray *protocolNames;
@property (nonatomic, readonly) NSString *protocolsString;

@property (nonatomic, readonly) NSArray *classMethods; // TODO: NSArray vs. NSMutableArray
- (void)addClassMethod:(CDOCMethod *)method;

@property (nonatomic, readonly) NSArray *instanceMethods;
- (void)addInstanceMethod:(CDOCMethod *)method;

@property (nonatomic, readonly) NSArray *optionalClassMethods;
- (void)addOptionalClassMethod:(CDOCMethod *)method;

@property (nonatomic, readonly) NSArray *optionalInstanceMethods;
- (void)addOptionalInstanceMethod:(CDOCMethod *)method;

@property (nonatomic, readonly) NSArray *properties;
- (void)addProperty:(CDOCProperty *)property;

@property (nonatomic, readonly) BOOL hasMethods;

- (void)registerTypesWithObject:(CDTypeController *)typeController phase:(NSUInteger)phase;
- (void)registerTypesFromMethods:(NSArray *)methods withObject:(CDTypeController *)typeController phase:(NSUInteger)phase;

- (NSComparisonResult)ascendingCompareByName:(CDOCProtocol *)other;

- (NSString *)methodSearchContext;
- (void)recursivelyVisit:(CDVisitor *)visitor;

- (void)visitMethods:(CDVisitor *)visitor propertyState:(CDVisitorPropertyState *)propertyState;

- (void)mergeMethodsFromProtocol:(CDOCProtocol *)other;
- (void)mergePropertiesFromProtocol:(CDOCProtocol *)other;

@end
