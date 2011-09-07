// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2011 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDMachOFile, CDSection, CDTypeController;
@class CDClassDump, CDVisitor;

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

@property (readonly) CDMachOFile *machOFile;
@property (readonly) BOOL hasObjectiveCData;

@property (readonly) CDSection *objcImageInfoSection;
@property (readonly) NSString *garbageCollectionStatus;

- (void)process;
- (void)loadProtocols;
- (void)loadClasses;
- (void)loadCategories;

- (void)registerTypesWithObject:(CDTypeController *)typeController phase:(NSUInteger)phase;
- (void)recursivelyVisit:(CDVisitor *)aVisitor;

- (void)createUniquedProtocols;

@end
