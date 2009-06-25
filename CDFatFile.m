// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import "CDFatFile.h"

#include <mach-o/arch.h>
#include <mach-o/fat.h>
#include <mach-o/swap.h>
#import <Foundation/Foundation.h>

#import "CDDataCursor.h"
#import "CDFatArch.h"
#import "CDMachOFile.h"

@implementation CDFatFile

- (id)initWithData:(NSData *)someData offset:(NSUInteger)anOffset;
{
    CDDataCursor *cursor;
    unsigned int index;
    struct fat_header header;

    if ([super initWithData:someData offset:anOffset] == nil)
        return nil;

    arches = [[NSMutableArray alloc] init];

    cursor = [[CDDataCursor alloc] initWithData:someData];
    [cursor setOffset:offset];
    header.magic = [cursor readBigInt32];

    NSLog(@"(testing fat) magic: 0x%x", header.magic);
    if (header.magic != FAT_MAGIC) {
        [cursor release];
        [self release];
        return nil;
    }

    header.nfat_arch = [cursor readBigInt32];
    NSLog(@"nfat_arch: %u", header.nfat_arch);
    for (index = 0; index < header.nfat_arch; index++) {
        CDFatArch *arch;

        arch = [[CDFatArch alloc] initWithDataCursor:cursor];
        [arch setFatFile:self];
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


// Case 1: no arch specified
//  - check main file for these, then lock down on that arch:
//    - local arch, 32 bit
//    - local arch, 64 bit
//    - any arch, 32 bit
//    - any arch, 64 bit
//
// Case 2: you specified a specific arch (i386, x86_64, ppc, ppc7400, ppc64, etc.)
//  - only that arch
//
// In either case, we can ignore the cpu subtype

- (NSString *)bestMatchForLocalArch;
{
    const NXArchInfo *archInfo;
    cpu_type_t targetType;
    BOOL didFind64BitArch = NO;

    archInfo = NXGetLocalArchInfo();
    if (archInfo == NULL) {
        fprintf(stderr, "Error: Couldn't get local architecture\n");
        return nil;
    }

    targetType = archInfo->cputype & ~CPU_ARCH_MASK;

    // This architecture, 32 bit
    for (CDFatArch *fatArch in arches) {
        if ([fatArch cpuType] == targetType && [fatArch uses64BitABI] == NO)
            return [fatArch archName];
    }

    // This architecture, 64 bit
    for (CDFatArch *fatArch in arches) {
#ifdef __LP64__
        if ([fatArch cpuType] == targetType && [fatArch uses64BitABI])
            return [fatArch archName];
#else
        if ([fatArch cpuType] == targetType && [fatArch uses64BitABI])
            didFind64BitArch = YES;
#endif
    }

    // Any architecture, 32 bit
    for (CDFatArch *fatArch in arches) {
        if ([fatArch uses64BitABI] == NO)
            return [fatArch archName];
    }

    // Any architecture, 64 bit
    for (CDFatArch *fatArch in arches) {
#ifdef __LP64__
        if ([fatArch uses64BitABI])
            return [fatArch archName];
#else
        if ([fatArch uses64BitABI])
            didFind64BitArch = YES;
#endif
    }

#ifdef __LP64__
    // Any architecture
    if ([arches count] > 0)
        return [arches objectAtIndex:0];
#else
    if (didFind64BitArch)
        fprintf(stderr, "Error: Can't dump 64-bit files with 32-bit version of class-dump\n");
#endif

    return nil;
}

- (CDMachOFile *)machOFileWithArchName:(NSString *)name;
{
    const NXArchInfo *archInfo;
    cpu_type_t maskedCPUType;

    archInfo = NXGetArchInfoFromName([name UTF8String]);
    if (archInfo == NULL)
        return nil;

    maskedCPUType = archInfo->cputype & ~CPU_ARCH_MASK;
    for (CDFatArch *arch in arches) {
        if ([arch cpuType] == maskedCPUType)
            return [arch machOFile];
    }

    return nil;
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
