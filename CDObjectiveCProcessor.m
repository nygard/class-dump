//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2009 Steve Nygard.  All rights reserved.

#import "CDObjectiveCProcessor.h"

#import "CDClassDump.h"
#import "CDMachOFile.h"
#import "CDVisitor.h"
#import "NSArray-Extensions.h"
#import "CDLCSegment.h"

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
    return [self hasObjectiveC1Data] || [self hasObjectiveC2Data];
}

- (BOOL)hasObjectiveC1Data;
{
    return [machOFile segmentWithName:@"__OBJC"] != nil;
}

- (BOOL)hasObjectiveC2Data;
{
    return [[machOFile segmentWithName:@"__DATA"] sectionWithName:@"__objc_classlist"] != nil;
}

- (void)process;
{
    // Implement in subclasses.
}

- (void)registerStructuresWithObject:(id <CDStructureRegistration>)anObject phase:(int)phase;
{
    for (CDOCClass *aClass in classes)
        [aClass registerStructuresWithObject:anObject phase:phase];

    for (CDOCCategory *category in categories)
        [category registerStructuresWithObject:anObject phase:phase];

    for (NSString *name in [[protocolsByName allKeys] sortedArrayUsingSelector:@selector(compare:)])
        [[protocolsByName objectForKey:name] registerStructuresWithObject:anObject phase:phase];
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

    if ([protocolNames count] > 0 || [classesAndCategories count] > 0) {
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

    // And finally fill in adopted protocols, instance and class methods
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
            NSParameterAssert([[uniqueProtocol classMethods] count] == [[p1 classMethods] count]);
        }

        if ([[uniqueProtocol instanceMethods] count] == 0) {
            for (CDOCMethod *method in [p1 instanceMethods])
                [uniqueProtocol addInstanceMethod:method];
        } else {
            NSParameterAssert([[uniqueProtocol instanceMethods] count] == [[p1 instanceMethods] count]);
        }

        if ([[uniqueProtocol optionalClassMethods] count] == 0) {
            for (CDOCMethod *method in [p1 optionalClassMethods])
                [uniqueProtocol addOptionalClassMethod:method];
        } else {
            NSParameterAssert([[uniqueProtocol optionalClassMethods] count] == [[p1 optionalClassMethods] count]);
        }

        if ([[uniqueProtocol optionalInstanceMethods] count] == 0) {
            for (CDOCMethod *method in [p1 optionalInstanceMethods])
                [uniqueProtocol addOptionalInstanceMethod:method];
        } else {
            NSParameterAssert([[uniqueProtocol optionalInstanceMethods] count] == [[p1 optionalInstanceMethods] count]);
        }
    }

    //NSLog(@"protocolsByName: %@", protocolsByName);
}

@end
