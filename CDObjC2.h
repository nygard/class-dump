// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2009 Steve Nygard.  All rights reserved.

#import "CDObjectiveCProcessor.h"

@interface CDObjC2 : CDObjectiveCProcessor
{
}

- (id)initWithMachOFile:(CDMachOFile *)aMachOFile;

- (BOOL)hasObjectiveCData;

- (void)process;

- (id)loadClassAtAddress:(uint64_t)address;
- (NSArray *)loadMethodsAtAddress:(uint64_t)address;

@end
