// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDObjectiveCProcessor.h"

#import "CDClassDump.h"
#import "CDMachOFile.h"
#import "CDVisitor.h"
#import "CDLCSegment.h"
#import "CDLCDynamicSymbolTable.h"
#import "CDLCSymbolTable.h"
#import "CDOCProtocol.h"
#import "CDTypeController.h"

// Note: sizeof(long long) == 8 on both 32-bit and 64-bit.  sizeof(uint64_t) == 8.  So use [NSNumber numberWithUnsignedLongLong:].

@implementation CDObjectiveCProcessor
{
    CDMachOFile *machOFile;
    
    NSMutableArray *classes;
    NSMutableDictionary *classesByAddress;
    
    NSMutableArray *categories;
    
    NSMutableDictionary *protocolsByName; // uniqued
    NSMutableDictionary *protocolsByAddress; // non-uniqued
}

- (id)initWithMachOFile:(CDMachOFile *)aMachOFile;
{
    if ((self = [super init])) {
        machOFile = [aMachOFile retain];
        classes = [[NSMutableArray alloc] init];
        classesByAddress = [[NSMutableDictionary alloc] init];
        categories = [[NSMutableArray alloc] init];
        protocolsByName = [[NSMutableDictionary alloc] init];
        protocolsByAddress = [[NSMutableDictionary alloc] init];
    }

    return self;
}

- (void)dealloc;
{
    [machOFile release];
    [classes release];
    [classesByAddress release];
    [categories release];
    [protocolsByName release];
    [protocolsByAddress release];

    [super dealloc];
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> machOFile: %@",
            NSStringFromClass([self class]), self,
            machOFile.filename];
}

#pragma mark -

@synthesize machOFile;

- (BOOL)hasObjectiveCData;
{
    return machOFile.hasObjectiveC1Data || machOFile.hasObjectiveC2Data;
}

- (CDSection *)objcImageInfoSection;
{
    // Implement in subclasses.
    return nil;
}

- (NSString *)garbageCollectionStatus;
{
    if (self.objcImageInfoSection != nil) {
        CDMachOFileDataCursor *cursor = [[CDMachOFileDataCursor alloc] initWithSection:self.objcImageInfoSection];
        
        [cursor readInt32];
        uint32_t v2 = [cursor readInt32];
        //NSLog(@"%s: %08x %08x", __cmd, v1, v2);
        // v2 == 0 -> Objective-C Garbage Collection: Unsupported
        // v2 == 2 -> Supported
        // v2 == 6 -> Required
        //NSParameterAssert(v2 == 0 || v2 == 2 || v2 == 6);
        
        [cursor release];
        
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
    [classes addObject:aClass];
    [classesByAddress setObject:aClass forKey:[NSNumber numberWithUnsignedLongLong:address]];
}

- (CDOCClass *)classWithAddress:(uint64_t)address;
{
    return [classesByAddress objectForKey:[NSNumber numberWithUnsignedLongLong:address]];
}

- (void)addClassesFromArray:(NSArray *)anArray;
{
    if (anArray != nil)
        [classes addObjectsFromArray:anArray];
}

- (void)addCategoriesFromArray:(NSArray *)anArray;
{
    if (anArray != nil)
        [categories addObjectsFromArray:anArray];
}

- (CDOCProtocol *)protocolWithAddress:(uint64_t)address;
{
    NSNumber *key = [NSNumber numberWithUnsignedLongLong:address];
    return [protocolsByAddress objectForKey:key];
}

- (void)setProtocol:(CDOCProtocol *)aProtocol withAddress:(uint64_t)address;
{
    NSNumber *key = [NSNumber numberWithUnsignedLongLong:address];
    [protocolsByAddress setObject:aProtocol forKey:key];
}

- (CDOCProtocol *)protocolForName:(NSString *)name;
{
    return [protocolsByName objectForKey:name];
}

- (void)addCategory:(CDOCCategory *)category;
{
    if (category != nil)
        [categories addObject:category];
}

#pragma mark - Processing

- (void)process;
{
    if (machOFile.isEncrypted == NO && machOFile.canDecryptAllSegments) {
        [machOFile.symbolTable loadSymbols];
        [machOFile.dynamicSymbolTable loadSymbols];

        [self loadProtocols];

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
    for (CDOCClass *aClass in classes)
        [aClass registerTypesWithObject:typeController phase:phase];

    for (CDOCCategory *category in categories)
        [category registerTypesWithObject:typeController phase:phase];

    for (NSString *name in [[protocolsByName allKeys] sortedArrayUsingSelector:@selector(compare:)])
        [[protocolsByName objectForKey:name] registerTypesWithObject:typeController phase:phase];
}

- (void)recursivelyVisit:(CDVisitor *)aVisitor;
{
    NSMutableArray *classesAndCategories = [[NSMutableArray alloc] init];
    [classesAndCategories addObjectsFromArray:classes];
    [classesAndCategories addObjectsFromArray:categories];

    // TODO: Sort protocols by dependency
    // TODO (2004-01-30): It looks like protocols might be defined in more than one file.  i.e. NSObject.
    // TODO (2004-02-02): Looks like we need to record the order the protocols were encountered, or just always sort protocols
    NSArray *protocolNames = [[protocolsByName allKeys] sortedArrayUsingSelector:@selector(compare:)];

    [aVisitor willVisitObjectiveCProcessor:self];
    [aVisitor visitObjectiveCProcessor:self];

    for (NSString *protocolName in protocolNames) {
        [[protocolsByName objectForKey:protocolName] recursivelyVisit:aVisitor];
    }

    if ([[aVisitor classDump] shouldSortClassesByInheritance]) {
        [classesAndCategories sortTopologically];
    } else if ([[aVisitor classDump] shouldSortClasses])
        [classesAndCategories sortUsingSelector:@selector(ascendingCompareByName:)];

    for (id aClassOrCategory in classesAndCategories)
        [aClassOrCategory recursivelyVisit:aVisitor];

    [classesAndCategories release];

    [aVisitor didVisitObjectiveCProcessor:self];
}

- (void)createUniquedProtocols;
{
    // Now unique the protocols by name and store in protocolsByName

    for (NSNumber *key in [[protocolsByAddress allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        CDOCProtocol *p1 = [protocolsByAddress objectForKey:key];
        CDOCProtocol *p2 = [protocolsByName objectForKey:[p1 name]];
        if (p2 == nil) {
            p2 = [[CDOCProtocol alloc] init];
            [p2 setName:[p1 name]];
            [protocolsByName setObject:p2 forKey:[p2 name]];
            // adopted protocols still not set, will want uniqued instances
            [p2 release];
        } else {
        }
    }

    //NSLog(@"uniqued protocol names: %@", [[[protocolsByName allKeys] sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@", "]);

    // And finally fill in adopted protocols, instance and class methods.  And properties.
    for (NSNumber *key in [[protocolsByAddress allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        CDOCProtocol *p1 = [protocolsByAddress objectForKey:key];
        CDOCProtocol *uniqueProtocol = [protocolsByName objectForKey:[p1 name]];
        for (CDOCProtocol *p2 in [p1 protocols])
            [uniqueProtocol addProtocol:[protocolsByName objectForKey:[p2 name]]];

        if ([[uniqueProtocol classMethods] count] == 0) {
            for (CDOCMethod *method in [p1 classMethods])
                [uniqueProtocol addClassMethod:method];
        } else {
            NSParameterAssert([[p1 classMethods] count] == 0 || [[uniqueProtocol classMethods] count] == [[p1 classMethods] count]);
        }

        if ([[uniqueProtocol instanceMethods] count] == 0) {
            for (CDOCMethod *method in [p1 instanceMethods])
                [uniqueProtocol addInstanceMethod:method];
        } else {
            if (!([[p1 instanceMethods] count] == 0 || [[uniqueProtocol instanceMethods] count] == [[p1 instanceMethods] count])) {
                //NSLog(@"p1 name: %@, uniqueProtocol name: %@", [p1 name], [uniqueProtocol name]);
                //NSLog(@"p1 instanceMethods: %@", [p1 instanceMethods]);
                //NSLog(@"uniqueProtocol instanceMethods: %@", [uniqueProtocol instanceMethods]);
            }
            NSParameterAssert([[p1 instanceMethods] count] == 0 || [[uniqueProtocol instanceMethods] count] == [[p1 instanceMethods] count]);
        }

        if ([[uniqueProtocol optionalClassMethods] count] == 0) {
            for (CDOCMethod *method in [p1 optionalClassMethods])
                [uniqueProtocol addOptionalClassMethod:method];
        } else {
            NSParameterAssert([[p1 optionalClassMethods] count] == 0 || [[uniqueProtocol optionalClassMethods] count] == [[p1 optionalClassMethods] count]);
        }

        if ([[uniqueProtocol optionalInstanceMethods] count] == 0) {
            for (CDOCMethod *method in [p1 optionalInstanceMethods])
                [uniqueProtocol addOptionalInstanceMethod:method];
        } else {
            NSParameterAssert([[p1 optionalInstanceMethods] count] == 0 || [[uniqueProtocol optionalInstanceMethods] count] == [[p1 optionalInstanceMethods] count]);
        }

        if ([[uniqueProtocol properties] count] == 0) {
            for (CDOCProperty *property in [p1 properties])
                [uniqueProtocol addProperty:property];
        } else {
            NSParameterAssert([[p1 properties] count] == 0 || [[uniqueProtocol properties] count] == [[p1 properties] count]);
        }
    }

    //NSLog(@"protocolsByName: %@", protocolsByName);
}

@end
