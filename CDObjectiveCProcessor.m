//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2009 Steve Nygard.  All rights reserved.

#import "CDObjectiveCProcessor.h"

#import "CDClassDump.h"
#import "CDMachOFile.h"
#import "CDVisitor.h"
#import "NSArray-Extensions.h"

@implementation CDObjectiveCProcessor

- (id)initWithMachOFile:(CDMachOFile *)aMachOFile;
{
    if ([super init] == nil)
        return nil;

    machOFile = [aMachOFile retain];
    classes = [[NSMutableArray alloc] init];
    categories = [[NSMutableArray alloc] init];
    protocolsByName = [[NSMutableDictionary alloc] init];

    return self;
}

- (void)dealloc;
{
    [machOFile release];
    [classes release];
    [categories release];
    [protocolsByName release];

    [super dealloc];
}

- (CDMachOFile *)machOFile;
{
    return machOFile;
}

- (BOOL)hasObjectiveCData;
{
    // Implement in subclasses.
    return NO;
}

- (void)process;
{
    // Implement in subclasses.
}

- (void)registerStructuresWithObject:(id <CDStructureRegistration>)anObject phase:(int)phase;
{
    // Implement in subclasses.
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

@end
