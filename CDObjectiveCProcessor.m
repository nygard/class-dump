// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDObjectiveCProcessor.h"

#import "CDClassDump.h"
#import "CDMachOFile.h"
#import "CDVisitor.h"
#import "NSArray-Extensions.h"
#import "CDLCSegment.h"
#import "CDLCDynamicSymbolTable.h"
#import "CDLCSymbolTable.h"
#import "CDOCProtocol.h"
#import "CDTypeController.h"

// Note: sizeof(long long) == 8 on both 32-bit and 64-bit.  sizeof(uint64_t) == 8.  So use [NSNumber numberWithUnsignedLongLong:].

@implementation CDObjectiveCProcessor

- (id)initWithMachOFile:(CDMachOFile *)aMachOFile;
{
    if ([super init] == nil)
        return nil;

    machOFile = [aMachOFile retain];
    classes = [[NSMutableArray alloc] init];
    classesByAddress = [[NSMutableDictionary alloc] init];
    categories = [[NSMutableArray alloc] init];
    protocolsByName = [[NSMutableDictionary alloc] init];
    protocolsByAddress = [[NSMutableDictionary alloc] init];

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

- (CDMachOFile *)machOFile;
{
    return machOFile;
}

- (BOOL)hasObjectiveCData;
{
    return [machOFile hasObjectiveC1Data] || [machOFile hasObjectiveC2Data];
}

- (void)process;
{
    if ([machOFile isEncrypted] == NO && [machOFile canDecryptAllSegments]) {
        [[machOFile symbolTable] loadSymbols];
        [[machOFile dynamicSymbolTable] loadSymbols];

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

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> machOFile: %@",
                     NSStringFromClass([self class]), self,
                     [machOFile filename]];
}

- (void)recursivelyVisit:(CDVisitor *)aVisitor;
{
    NSMutableArray *classesAndCategories;
    NSArray *protocolNames;

    classesAndCategories = [[NSMutableArray alloc] init];
    [classesAndCategories addObjectsFromArray:classes];
    [classesAndCategories addObjectsFromArray:categories];

    // TODO: Sort protocols by dependency
    // TODO (2004-01-30): It looks like protocols might be defined in more than one file.  i.e. NSObject.
    // TODO (2004-02-02): Looks like we need to record the order the protocols were encountered, or just always sort protocols
    protocolNames = [[protocolsByName allKeys] sortedArrayUsingSelector:@selector(compare:)];

    [aVisitor willVisitObjectiveCProcessor:self];

    // Skip if there are no protocols, classes, or categories to print.
    // But don't skip if the file is encrypted or has segments that can't be decrypted.
    if ([protocolNames count] > 0 || [classesAndCategories count] > 0 || [machOFile isEncrypted] || [machOFile canDecryptAllSegments] == NO) {
        [aVisitor visitObjectiveCProcessor:self];
    }

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
        CDOCProtocol *p1, *p2;

        p1 = [protocolsByAddress objectForKey:key];
        p2 = [protocolsByName objectForKey:[p1 name]];
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
        CDOCProtocol *p1, *uniqueProtocol;

        p1 = [protocolsByAddress objectForKey:key];
        uniqueProtocol = [protocolsByName objectForKey:[p1 name]];
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

- (NSData *)objcImageInfoData;
{
    // Good for objc2.  Use __OBJC segment for objc1.
    return [[[machOFile segmentWithName:@"__DATA"] sectionWithName:@"__objc_imageinfo"] data];
}

- (NSString *)garbageCollectionStatus;
{
    NSData *sectionData;
    CDDataCursor *cursor;
    uint32_t v1, v2;

    sectionData = [self objcImageInfoData];
    if ([sectionData length] < 8)
        return @"Unknown";

    cursor = [[CDDataCursor alloc] initWithData:sectionData];
    [cursor setByteOrder:[machOFile byteOrder]];

    v1 = [cursor readInt32];
    v2 = [cursor readInt32];
    //NSLog(@"%s: %08x %08x", _cmd, v1, v2);
    // v2 == 0 -> Objective-C Garbage Collection: Unsupported
    // v2 == 2 -> Supported
    // v2 == 6 -> Required
    NSParameterAssert(v2 == 0 || v2 == 2 || v2 == 6);

    [cursor release];

    // These are probably bitfields that should be tested/masked...
    switch (v2) {
      case 0: return @"Unsupported";
      case 2: return @"Supported";
      case 6: return @"Required";
    }

    return [NSString stringWithFormat:@"Unknown (0x%08x)", v2];
}

@end
