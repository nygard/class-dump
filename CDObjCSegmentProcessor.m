//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import "CDObjCSegmentProcessor.h"

#import "rcsid.h"
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

RCS_ID("$Header: /Volumes/Data/tmp/Tools/class-dump/CDObjCSegmentProcessor.m,v 1.20 2004/07/07 22:56:43 nygard Exp $");

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

- (void)appendFormattedString:(NSMutableString *)resultString classDump:(CDClassDump *)aClassDump;
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

    if ([protocolNames count] > 0 || [allClasses count] > 0) {
        [resultString appendString:@"/*\n"];
        [resultString appendFormat:@" * File: %@\n", [machOFile filename]];
        if ([machOFile filetype] == MH_DYLIB) {
            CDDylibCommand *identifier;

            identifier = [machOFile dylibIdentifier];
            if (identifier != nil)
                [resultString appendFormat:@" *       Current version: %@, Compatibility version: %@\n",
                              [identifier formattedCurrentVersion], [identifier formattedCompatibilityVersion]];
        }
        [resultString appendString:@" */\n\n"];
    }

    count = [protocolNames count];
    for (index = 0; index < count; index++) {
        CDOCProtocol *aProtocol;

        aProtocol = [protocolsByName objectForKey:[protocolNames objectAtIndex:index]];
        [aProtocol appendToString:resultString classDump:aClassDump symbolReferences:nil];
    }

    if ([aClassDump shouldSortClassesByInheritance] == YES) {
        [allClasses sortTopologically];
    } else if ([aClassDump shouldSortClasses] == YES)
        [allClasses sortUsingSelector:@selector(ascendingCompareByName:)];

    count = [allClasses count];
    for (index = 0; index < count; index++)
        [[allClasses objectAtIndex:index] appendToString:resultString classDump:aClassDump symbolReferences:nil];

    [allClasses release];
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

- (void)registerClassesWithObject:(NSMutableDictionary *)aDictionary;
{
    NSString *importBaseName;

    importBaseName = [machOFile importBaseName];
    if (importBaseName != nil) {
        int count, index;

        count = [modules count];
        for (index = 0; index < count; index++) {
            [[modules objectAtIndex:index] registerClassesWithObject:aDictionary frameworkName:importBaseName];
        }
    }
}

- (void)generateSeparateHeadersClassDump:(CDClassDump *)aClassDump;
{
    int count, index;

    count = [modules count];
    for (index = 0; index < count; index++)
        [[modules objectAtIndex:index] generateSeparateHeadersClassDump:aClassDump];
}

@end
