// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDObjectiveCProcessor.h"

@class CDOCClass, CDOCCategory, CDOCProtocol;

@interface CDObjectiveC2Processor : CDObjectiveCProcessor

- (void)loadProtocols;
- (void)loadClasses;
- (void)loadCategories;

- (CDOCProtocol *)protocolAtAddress:(uint64_t)address;
- (CDOCCategory *)loadCategoryAtAddress:(uint64_t)address;
- (CDOCClass *)loadClassAtAddress:(uint64_t)address;

- (NSArray *)loadPropertiesAtAddress:(uint64_t)address;
- (NSArray *)loadMethodsOfMetaClassAtAddress:(uint64_t)address;

- (NSArray *)loadMethodsAtAddress:(uint64_t)address;
- (NSArray *)loadIvarsAtAddress:(uint64_t)address;

- (NSArray *)uniquedProtocolListAtAddress:(uint64_t)address;

@property (nonatomic, readonly) CDSection *objcImageInfoSection;

@end
