// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import <Foundation/Foundation.h>

#import "CDStructureRegistrationProtocol.h"

@class CDClassDump, CDMachOFile;
@class CDVisitor;

@interface CDObjectiveCProcessor : NSObject
{
    CDMachOFile *machOFile;

    NSMutableArray *classes;
    NSMutableDictionary *classesByAddress;

    NSMutableArray *categories;

    NSMutableDictionary *protocolsByName; // uniqued
    NSMutableDictionary *protocolsByAddress; // non-uniqued
}

- (id)initWithMachOFile:(CDMachOFile *)aMachOFile;
- (void)dealloc;

- (CDMachOFile *)machOFile;

- (BOOL)hasObjectiveCData;

- (void)process;
- (void)loadProtocols;
- (void)loadClasses;
- (void)loadCategories;

- (void)registerStructuresWithObject:(id <CDStructureRegistration>)anObject phase:(int)phase;
- (void)recursivelyVisit:(CDVisitor *)aVisitor;

- (void)createUniquedProtocols;

- (NSData *)objcImageInfoData;
- (void)logGCStatus;

@end
