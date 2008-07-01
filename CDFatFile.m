//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2007  Steve Nygard

#import "CDFatFile.h"

#include <mach-o/arch.h>
#include <mach-o/fat.h>
#include <mach-o/swap.h>
#import <Foundation/Foundation.h>

#import "CDDataCursor.h"
#import "CDFatArch.h"
#import "CDMachOFile.h"

@implementation CDFatFile

- (id)initWithData:(NSData *)data;
{
    CDDataCursor *cursor;
    unsigned int magicNumber, count, index;

    if ([super init] == nil)
        return nil;

    arches = [[NSMutableArray alloc] init];

    cursor = [[CDDataCursor alloc] initWithData:data];
    if ([cursor readBigInt32:&magicNumber] == NO) {
        [cursor release];
        [self release];
        return nil;
    }

    NSLog(@"magic: 0x%x", magicNumber);
    if (magicNumber != FAT_MAGIC) {
        [cursor release];
        [self release];
        return nil;
    }

    if ([cursor readBigInt32:&count] == NO) {
        [cursor release];
        [self release];
        return nil;
    }

    NSLog(@"count: %u", count);
    for (index = 0; index < count; index++) {
        CDFatArch *arch;

        arch = [[CDFatArch alloc] initWithDataCursor:cursor];
        [arches addObject:arch];
        [arch release];
    }

    [cursor release];

    NSLog(@"arches: %@", arches);

    return self;
}

- (void)dealloc;
{
    [arches release];

    [super dealloc];
}

- (CDFatArch *)fatArchWithName:(NSString *)archName;
{
    if (archName == nil) {
        CDFatArch *fatArch;

        fatArch = [self localArchitecture];
        if (fatArch == nil && [arches count] > 0)
            fatArch = [arches objectAtIndex:0];

        return fatArch;
    }

    return [self _fatArchWithName:archName];
}

- (CDFatArch *)_fatArchWithName:(NSString *)archName;
{
    for (CDFatArch *arch in arches)
        if ([[arch archName] isEqual:archName])
            return arch;

    return nil;
}

- (CDFatArch *)localArchitecture;
{
    const NXArchInfo *archInfo;

    archInfo = NXGetLocalArchInfo();
    if (archInfo == NULL) {
        NSLog(@"Couldn't get local architecture");
        return nil;
    }

    //NSLog(@"Local arch: %d, %s (%s)", archInfo->cputype, archInfo->description, archInfo->name);

    // TODO (2007-11-04): Hmm.  Search first for exact match, then fall back to main cputype.
    return [self _fatArchWithName:CDNameForCPUType(archInfo->cputype, archInfo->cpusubtype)];
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%p] CDFatFile with %u arches", self, [arches count]];
}

- (NSArray *)archNames;
{
    NSMutableArray *archNames;

    archNames = [NSMutableArray array];
    for (CDFatArch *arch in arches)
        [archNames addObject:[arch archName]];

    return archNames;
}

@end
