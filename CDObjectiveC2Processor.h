// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2009 Steve Nygard.  All rights reserved.

#import "CDObjectiveCProcessor.h"

@class CDOCClass;

@interface CDObjectiveC2Processor : CDObjectiveCProcessor
{
    NSMutableArray *classes;
}

- (id)initWithMachOFile:(CDMachOFile *)aMachOFile;
- (void)dealloc;

- (BOOL)hasObjectiveCData;

- (void)process;

- (CDOCClass *)loadClassAtAddress:(uint64_t)address;
- (NSArray *)loadMethodsAtAddress:(uint64_t)address;
- (NSArray *)loadIvarsAtAddress:(uint64_t)address;

@end
