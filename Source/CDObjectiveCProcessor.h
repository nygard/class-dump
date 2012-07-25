// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDMachOFile, CDSection, CDTypeController;
@class CDClassDump, CDVisitor;
@class CDOCClass, CDOCCategory, CDOCProtocol;

@interface CDObjectiveCProcessor : NSObject

- (id)initWithMachOFile:(CDMachOFile *)machOFile;

@property (readonly) CDMachOFile *machOFile;
@property (nonatomic, readonly) BOOL hasObjectiveCData;

@property (nonatomic, readonly) CDSection *objcImageInfoSection;
@property (nonatomic, readonly) NSString *garbageCollectionStatus;

- (void)addClass:(CDOCClass *)aClass withAddress:(uint64_t)address;
- (CDOCClass *)classWithAddress:(uint64_t)address;

- (void)addClassesFromArray:(NSArray *)array;
- (void)addCategoriesFromArray:(NSArray *)array;

- (CDOCProtocol *)protocolWithAddress:(uint64_t)address;
- (void)setProtocol:(CDOCProtocol *)aProtocol withAddress:(uint64_t)address;

- (CDOCProtocol *)protocolForName:(NSString *)name;

- (void)addCategory:(CDOCCategory *)category;

- (void)process;
- (void)loadProtocols;
- (void)loadClasses;
- (void)loadCategories;

- (void)registerTypesWithObject:(CDTypeController *)typeController phase:(NSUInteger)phase;
- (void)recursivelyVisit:(CDVisitor *)visitor;

- (void)createUniquedProtocols;

@end
