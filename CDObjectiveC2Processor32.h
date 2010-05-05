// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDObjectiveCProcessor.h"

@class CDOCClass, CDOCCategory, CDOCProtocol;

@interface CDObjectiveC2Processor32 : CDObjectiveCProcessor
{
}

- (void)loadProtocols;
- (void)loadClasses;
- (void)loadCategories;

- (CDOCProtocol *)protocolAtAddress:(uint32_t)address;
- (CDOCCategory *)loadCategoryAtAddress:(uint32_t)address;
- (CDOCClass *)loadClassAtAddress:(uint32_t)address;

- (NSArray *)loadPropertiesAtAddress:(uint32_t)address;
- (NSArray *)loadMethodsOfMetaClassAtAddress:(uint32_t)address;

- (NSArray *)loadMethodsAtAddress:(uint32_t)address;
- (NSArray *)loadIvarsAtAddress:(uint32_t)address;

- (NSArray *)uniquedProtocolListAtAddress:(uint32_t)address;

@end
