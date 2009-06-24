// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import "CDObjectiveC1Processor.h"

#include <mach-o/arch.h>

#import "CDClassDump.h"
#import "CDLCDylib.h"
#import "CDMachOFile.h"
#import "CDOCCategory.h"
#import "CDOCClass.h"
#import "CDOCIvar.h"
#import "CDOCMethod.h"
#import "CDOCModule.h"
#import "CDOCProtocol.h"
#import "CDOCSymtab.h"
#import "CDSection32.h"
#import "CDLCSegment32.h"
#import "NSArray-Extensions.h"
#import "CDObjectiveC1Processor-Private.h"
#import "CDVisitor.h"

@implementation CDObjectiveC1Processor

- (id)initWithMachOFile:(CDMachOFile *)aMachOFile;
{
    if ([super initWithMachOFile:aMachOFile] == nil)
        return nil;

    modules = [[NSMutableArray alloc] init];
    protocolsByName = [[NSMutableDictionary alloc] init];
    protocolsByAddress = [[NSMutableDictionary alloc] init];

    return self;
}

- (void)dealloc;
{
    [modules release];
    [protocolsByName release];
    [protocolsByAddress release];

    [super dealloc];
}

- (NSArray *)modules;
{
    return modules;
}

- (BOOL)hasObjectiveCData;
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

- (void)recursivelyVisit:(CDVisitor *)aVisitor;
{
    NSMutableArray *allClasses;
    NSArray *protocolNames;

    allClasses = [[NSMutableArray alloc] init];

    for (CDOCModule *module in modules) {
        NSArray *moduleClasses, *moduleCategories;

        moduleClasses = [[module symtab] classes];
        if (moduleClasses != nil)
            [allClasses addObjectsFromArray:moduleClasses];

        moduleCategories = [[module symtab] categories];
        if (moduleCategories != nil)
            [allClasses addObjectsFromArray:moduleCategories];
    }

    // TODO: Sort protocols by dependency
    // TODO (2004-01-30): It looks like protocols might be defined in more than one file.  i.e. NSObject.
    // TODO (2004-02-02): Looks like we need to record the order the protocols were encountered, or just always sort protocols
    protocolNames = [[protocolsByName allKeys] sortedArrayUsingSelector:@selector(compare:)];

    [aVisitor willVisitObjectiveCProcessor:self];

    if ([protocolNames count] > 0 || [allClasses count] > 0 || [machOFile hasProtectedSegments]) {
        [aVisitor visitObjectiveCProcessor:self];
    }

    for (NSString *protocolName in protocolNames) {
        [[protocolsByName objectForKey:protocolName] recursivelyVisit:aVisitor];
    }

    if ([[aVisitor classDump] shouldSortClassesByInheritance] == YES) {
        [allClasses sortTopologically];
    } else if ([[aVisitor classDump] shouldSortClasses] == YES)
        [allClasses sortUsingSelector:@selector(ascendingCompareByName:)];

    for (CDOCClass *aClass in allClasses)
        [aClass recursivelyVisit:aVisitor];

    [allClasses release];

    [aVisitor didVisitObjectiveCProcessor:self];
}

@end
