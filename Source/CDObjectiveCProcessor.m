// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDObjectiveCProcessor.h"

#import "CDClassDump.h"
#import "CDMachOFile.h"
#import "CDVisitor.h"
#import "CDLCSegment.h"
#import "CDLCDynamicSymbolTable.h"
#import "CDLCSymbolTable.h"
#import "CDOCProtocol.h"
#import "CDTypeController.h"
#import "CDOCClass.h"
#import "CDOCCategory.h"
#import "CDSection.h"
#import "CDProtocolUniquer.h"

// Note: sizeof(long long) == 8 on both 32-bit and 64-bit.  sizeof(uint64_t) == 8.  So use [NSNumber numberWithUnsignedLongLong:].

@implementation CDObjectiveCProcessor
{
    CDMachOFile *_machOFile;
    
    NSMutableArray *_classes;
    NSMutableDictionary *_classesByAddress;
    
    NSMutableArray *_categories;
    
    CDProtocolUniquer *_protocolUniquer;
}

- (id)initWithMachOFile:(CDMachOFile *)machOFile;
{
    if ((self = [super init])) {
        _machOFile = machOFile;
        _classes = [[NSMutableArray alloc] init];
        _classesByAddress = [[NSMutableDictionary alloc] init];
        _categories = [[NSMutableArray alloc] init];
        
        _protocolUniquer = [[CDProtocolUniquer alloc] init];
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> machOFile: %@",
            NSStringFromClass([self class]), self,
            self.machOFile.filename];
}

#pragma mark -

- (BOOL)hasObjectiveCData;
{
    return self.machOFile.hasObjectiveC1Data || self.machOFile.hasObjectiveC2Data;
}

- (CDSection *)objcImageInfoSection;
{
    // Implement in subclasses.
    return nil;
}

- (NSString *)garbageCollectionStatus;
{
    if (self.objcImageInfoSection != nil) {
        // The SDK frameworks (i.e. within Xcode, not in /System) have empty sections.
        if (self.objcImageInfoSection.size < 8)
            return @"Unknown";

        CDMachOFileDataCursor *cursor = [[CDMachOFileDataCursor alloc] initWithSection:self.objcImageInfoSection];
        
        [cursor readInt32];
        uint32_t v2 = [cursor readInt32];
        //NSLog(@"%s: %08x %08x", __cmd, v1, v2);
        // v2 == 0 -> Objective-C Garbage Collection: Unsupported
        // v2 == 2 -> Supported
        // v2 == 6 -> Required
        //NSParameterAssert(v2 == 0 || v2 == 2 || v2 == 6);
        
        // See markgc.c in the objc4 project
        switch (v2 & 0x06) {
            case 0: return @"Unsupported";
            case 2: return @"Supported";
            case 6: return @"Required";
        }
        
        return [NSString stringWithFormat:@"Unknown (0x%08x)", v2];
    }
    
    return nil;
}

#pragma mark -

- (void)addClass:(CDOCClass *)aClass withAddress:(uint64_t)address;
{
    [_classes addObject:aClass];
    [_classesByAddress setObject:aClass forKey:[NSNumber numberWithUnsignedLongLong:address]];
}

- (CDOCClass *)classWithAddress:(uint64_t)address;
{
    return [_classesByAddress objectForKey:[NSNumber numberWithUnsignedLongLong:address]];
}

- (void)addClassesFromArray:(NSArray *)array;
{
    if (array != nil)
        [_classes addObjectsFromArray:array];
}

- (void)addCategoriesFromArray:(NSArray *)array;
{
    if (array != nil)
        [_categories addObjectsFromArray:array];
}

- (void)addCategory:(CDOCCategory *)category;
{
    if (category != nil)
        [_categories addObject:category];
}

#pragma mark - Processing

- (void)process;
{
    if (self.machOFile.isEncrypted == NO && self.machOFile.canDecryptAllSegments) {
        [self.machOFile.symbolTable loadSymbols];
        [self.machOFile.dynamicSymbolTable loadSymbols];

        [self loadProtocols];
        [self.protocolUniquer createUniquedProtocols];

        // Load classes before categories, so we can get a dictionary of classes by address.
        [self loadClasses];
        [self loadCategories];
    }
}

- (void)loadProtocols;
{
    // Implement in subclasses.
}

- (void)loadClasses;
{
    // Implement in subclasses.
}

- (void)loadCategories;
{
    // Implement in subclasses.
}


- (void)registerTypesWithObject:(CDTypeController *)typeController phase:(NSUInteger)phase;
{
    for (CDOCClass *aClass in _classes)
        [aClass registerTypesWithObject:typeController phase:phase];

    for (CDOCCategory *category in _categories)
        [category registerTypesWithObject:typeController phase:phase];

    for (CDOCProtocol *protocol in [self.protocolUniquer uniqueProtocolsSortedByName])
        [protocol registerTypesWithObject:typeController phase:phase];
}

- (void)recursivelyVisit:(CDVisitor *)visitor;
{
    NSMutableArray *classesAndCategories = [[NSMutableArray alloc] init];
    [classesAndCategories addObjectsFromArray:_classes];
    [classesAndCategories addObjectsFromArray:_categories];

    [visitor willVisitObjectiveCProcessor:self];
    [visitor visitObjectiveCProcessor:self];
    
    // TODO: Sort protocols by dependency
    // TODO: (2004-01-30) It looks like protocols might be defined in more than one file.  i.e. NSObject.
    // TODO: (2004-02-02) Looks like we need to record the order the protocols were encountered, or just always sort protocols
    for (CDOCProtocol *protocol in [self.protocolUniquer uniqueProtocolsSortedByName])
        [protocol recursivelyVisit:visitor];

    if ([[visitor classDump] shouldSortClassesByInheritance]) {
        [classesAndCategories sortTopologically];
    } else if ([[visitor classDump] shouldSortClasses])
        [classesAndCategories sortUsingSelector:@selector(ascendingCompareByName:)];

    for (id aClassOrCategory in classesAndCategories)
        [aClassOrCategory recursivelyVisit:visitor];

    [visitor didVisitObjectiveCProcessor:self];
}

// Returns list of NSNumber containing the protocol addresses
- (NSArray *)protocolAddressListAtAddress:(uint64_t)address;
{
    // Implement in subclasses
    return nil;
}

@end
