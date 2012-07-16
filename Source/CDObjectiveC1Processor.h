// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDObjectiveCProcessor.h"

@class CDOCCategory, CDOCClass, CDOCProtocol, CDOCSymtab;

@interface CDObjectiveC1Processor : CDObjectiveCProcessor

- (id)initWithMachOFile:(CDMachOFile *)machOFile;

- (void)process;

// Formerly private
- (void)processModules;
- (CDOCSymtab *)processSymtabAtAddress:(uint32_t)address;
- (CDOCClass *)processClassDefinitionAtAddress:(uint32_t)address;
- (NSArray *)uniquedProtocolListAtAddress:(uint32_t)address;
- (NSArray *)processMethodsAtAddress:(uint32_t)address;
- (NSArray *)processMethodsAtAddress:(uint32_t)address isFromProtocolDefinition:(BOOL)isFromProtocolDefinition;
- (CDOCCategory *)processCategoryDefinitionAtAddress:(uint32_t)address;
- (CDOCProtocol *)protocolAtAddress:(uint32_t)address;

- (void)loadProtocols;

- (CDSection *)objcImageInfoSection;

@end
