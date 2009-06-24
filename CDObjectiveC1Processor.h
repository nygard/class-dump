// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import "CDObjectiveCProcessor.h"

@interface CDObjectiveC1Processor : CDObjectiveCProcessor
{
    NSMutableArray *modules;
    NSMutableDictionary *protocolsByName; // uniqued
    NSMutableDictionary *protocolsByAddress; // non-uniqued
}

- (id)initWithMachOFile:(CDMachOFile *)aMachOFile;
- (void)dealloc;

- (NSArray *)modules;

- (BOOL)hasObjectiveCData;
- (void)process;

- (void)registerStructuresWithObject:(id <CDStructureRegistration>)anObject phase:(int)phase;

- (void)recursivelyVisit:(CDVisitor *)aVisitor;

@end
