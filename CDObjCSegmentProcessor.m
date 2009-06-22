//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2007  Steve Nygard

#import "CDObjCSegmentProcessor.h"

#include <mach-o/arch.h>

#import <Foundation/Foundation.h>
#import "CDClassDump.h"
#import "CDDylibCommand.h"
#import "CDMachOFile.h"
#import "CDOCCategory.h"
#import "CDOCClass.h"
#import "CDOCIvar.h"
#import "CDOCMethod.h"
#import "CDOCModule.h"
#import "CDOCProtocol.h"
#import "CDOCSymtab.h"
#import "CDSection.h"
#import "CDSegmentCommand.h"
#import "NSArray-Extensions.h"
#import "CDObjCSegmentProcessor-Private.h"
#import "CDVisitor.h"

@implementation CDObjCSegmentProcessor

- (id)initWithMachOFile:(CDMachOFile *)aMachOFile;
{
    if ([super init] == nil)
        return nil;

    machOFile = [aMachOFile retain];
    modules = [[NSMutableArray alloc] init];
    protocolsByName = [[NSMutableDictionary alloc] init];
    protocolsByAddress = [[NSMutableDictionary alloc] init];

    return self;
}

- (void)dealloc;
{
    [machOFile release];
    [modules release];
    [protocolsByName release];
    [protocolsByAddress release];

    [super dealloc];
}

- (CDMachOFile *)machOFile;
{
    return machOFile;
}

- (NSArray *)modules;
{
    return modules;
}

- (BOOL)hasModules;
{
    return [modules count] > 0;
}

- (void)process;
{
    [self processProtocolSection];
    [self processModules];
}

- (void)registerStructuresWithObject:(id <CDStructureRegistration>)anObject phase:(int)phase;
{
    int count, index;
    NSArray *protocolNames;

    count = [modules count];
    for (index = 0; index < count; index++)
        [[[modules objectAtIndex:index] symtab] registerStructuresWithObject:anObject phase:phase];

    protocolNames = [[protocolsByName allKeys] sortedArrayUsingSelector:@selector(compare:)];
    count = [protocolNames count];
    for (index = 0; index < count; index++) {
        CDOCProtocol *aProtocol;

        aProtocol = [protocolsByName objectForKey:[protocolNames objectAtIndex:index]];
        [aProtocol registerStructuresWithObject:anObject phase:phase];
    }
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] machOFile: %@", NSStringFromClass([self class]), [machOFile filename]];
}

- (void)recursivelyVisit:(CDVisitor *)aVisitor;
{
    int count, index;
    NSMutableArray *allClasses;
    NSArray *protocolNames;

    allClasses = [[NSMutableArray alloc] init];

    count = [modules count];
    for (index = 0; index < count; index++) {
        NSArray *moduleClasses, *moduleCategories;

        moduleClasses = [[[modules objectAtIndex:index] symtab] classes];
        if (moduleClasses != nil)
            [allClasses addObjectsFromArray:moduleClasses];

        moduleCategories = [[[modules objectAtIndex:index] symtab] categories];
        if (moduleCategories != nil)
            [allClasses addObjectsFromArray:moduleCategories];
    }

    // TODO: Sort protocols by dependency
    // TODO (2004-01-30): It looks like protocols might be defined in more than one file.  i.e. NSObject.
    // TODO (2004-02-02): Looks like we need to record the order the protocols were encountered, or just always sort protocols
    protocolNames = [[protocolsByName allKeys] sortedArrayUsingSelector:@selector(compare:)];

    [aVisitor willVisitObjectiveCSegment:self];

    if ([protocolNames count] > 0 || [allClasses count] > 0 || [machOFile hasProtectedSegments]) {
        [aVisitor visitObjectiveCSegment:self];
    }

    count = [protocolNames count];
    for (index = 0; index < count; index++) {
        CDOCProtocol *aProtocol;

        aProtocol = [protocolsByName objectForKey:[protocolNames objectAtIndex:index]];
        [aProtocol recursivelyVisit:aVisitor];
    }

    if ([[aVisitor classDump] shouldSortClassesByInheritance] == YES) {
        [allClasses sortTopologically];
    } else if ([[aVisitor classDump] shouldSortClasses] == YES)
        [allClasses sortUsingSelector:@selector(ascendingCompareByName:)];

    count = [allClasses count];
    for (index = 0; index < count; index++)
        [[allClasses objectAtIndex:index] recursivelyVisit:aVisitor];

    [allClasses release];

    [aVisitor didVisitObjectiveCSegment:self];
}

@end
