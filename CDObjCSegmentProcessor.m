// This file is part of APPNAME, SHORT DESCRIPTION
// Copyright (C) 2003 Steve Nygard.  All rights reserved.

#import "CDObjCSegmentProcessor.h"

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

- (NSString *)formattedStringByModule;
{
    NSMutableString *resultString;
    int count, index;

    resultString = [NSMutableString string];

    // TODO: Show protocols

    count = [modules count];
    for (index = 0; index < count; index++)
        [[modules objectAtIndex:index] appendToString:resultString];

    return resultString;
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

- (void)registerStructsWithObject:(id <CDStructRegistration>)anObject;
{
    int count, index;
    NSArray *protocolNames;

    count = [modules count];
    for (index = 0; index < count; index++) {
        NSArray *moduleClasses, *moduleCategories;

        moduleClasses = [[[modules objectAtIndex:index] symtab] classes];
        [moduleClasses makeObjectsPerformSelector:_cmd withObject:anObject];

        moduleCategories = [[[modules objectAtIndex:index] symtab] categories];
        [moduleCategories makeObjectsPerformSelector:_cmd withObject:anObject];
    }

    protocolNames = [[protocolsByName allKeys] sortedArrayUsingSelector:@selector(compare:)];
    count = [protocolNames count];
    for (index = 0; index < count; index++) {
        CDOCProtocol *aProtocol;

        aProtocol = [protocolsByName objectForKey:[protocolNames objectAtIndex:index]];
        [aProtocol registerStructsWithObject:anObject];
    }
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] machOFile: %@", NSStringFromClass([self class]), [machOFile filename]];
}

@end
