//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import "CDObjCSegmentProcessor.h"

#import "rcsid.h"
#import <Foundation/Foundation.h>
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

RCS_ID("$Header: /Volumes/Data/tmp/Tools/class-dump/CDObjCSegmentProcessor.m,v 1.13 2004/01/15 03:20:54 nygard Exp $");

@implementation CDObjCSegmentProcessor

- (id)initWithMachOFile:(CDMachOFile *)aMachOFile;
{
    if ([super init] == nil)
        return nil;

    machOFile = [aMachOFile retain];
    modules = [[NSMutableArray alloc] init];
    protocolsByName = [[NSMutableDictionary alloc] init];

    return self;
}

- (void)dealloc;
{
    [machOFile release];
    [modules release];
    [protocolsByName release];

    [super dealloc];
}

- (void)process;
{
    [self processProtocolSection];
    [self processModules];
}

- (void)appendFormattedStringSortedByClass:(NSMutableString *)resultString classDump:(CDClassDump2 *)aClassDump;
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
    protocolNames = [[protocolsByName allKeys] sortedArrayUsingSelector:@selector(compare:)];

    if ([protocolNames count] > 0 || [allClasses count] > 0) {
        [resultString appendString:@"/*\n"];
        [resultString appendFormat:@" * File: %@\n", [machOFile filename]];
        [resultString appendString:@" */\n\n"];
    }

    count = [protocolNames count];
    for (index = 0; index < count; index++) {
        CDOCProtocol *aProtocol;

        aProtocol = [protocolsByName objectForKey:[protocolNames objectAtIndex:index]];
        [aProtocol appendToString:resultString classDump:aClassDump];
    }

    [allClasses sortUsingSelector:@selector(ascendingCompareByName:)];
    count = [allClasses count];
    for (index = 0; index < count; index++)
        [[allClasses objectAtIndex:index] appendToString:resultString classDump:aClassDump];

    [allClasses release];
}

- (void)registerStructuresWithObject:(id <CDStructRegistration>)anObject phase:(int)phase;
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

@end
