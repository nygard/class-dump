// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDFatFile.h"

#include <mach-o/arch.h>
#include <mach-o/fat.h>

#import "CDDataCursor.h"
#import "CDFatArch.h"
#import "CDMachOFile.h"

@implementation CDFatFile

- (id)initWithData:(NSData *)someData offset:(NSUInteger)anOffset filename:(NSString *)aFilename searchPathState:(CDSearchPathState *)aSearchPathState;
{
    CDDataCursor *cursor;
    unsigned int index;
    struct fat_header header;

    if ([super initWithData:someData offset:anOffset filename:aFilename searchPathState:aSearchPathState] == nil)
        return nil;

    arches = [[NSMutableArray alloc] init];

    cursor = [[CDDataCursor alloc] initWithData:someData];
    [cursor setOffset:offset];
    header.magic = [cursor readBigInt32];

    //NSLog(@"(testing fat) magic: 0x%x", header.magic);
    if (header.magic != FAT_MAGIC) {
        [cursor release];
        [self release];
        return nil;
    }

    header.nfat_arch = [cursor readBigInt32];
    //NSLog(@"nfat_arch: %u", header.nfat_arch);
    for (index = 0; index < header.nfat_arch; index++) {
        CDFatArch *arch;

        arch = [[CDFatArch alloc] initWithDataCursor:cursor];
        [arch setFatFile:self];
        [arches addObject:arch];
        [arch release];
    }

    [cursor release];

    //NSLog(@"arches: %@", arches);

    return self;
}

- (void)dealloc;
{
    [arches release];

    [super dealloc];
}


// Case 1: no arch specified
//  - check main file for these, then lock down on that arch:
//    - local arch, 64 bit
//    - local arch, 32 bit
//    - any arch, 64 bit
//    - any arch, 32 bit
//
// Case 2: you specified a specific arch (i386, x86_64, ppc, ppc7400, ppc64, etc.)
//  - only that arch
//
// In either case, we can ignore the cpu subtype

// Returns YES on success, NO on failure.
- (BOOL)bestMatchForLocalArch:(CDArch *)archPtr;
{
    const NXArchInfo *archInfo;
    cpu_type_t targetType;

    archInfo = NXGetLocalArchInfo();
    if (archInfo == NULL)
        return NO;

    if (archPtr == NULL)
        return [arches count] > 0;

    targetType = archInfo->cputype & ~CPU_ARCH_MASK;

#ifdef __LP64__
    // This architecture, 64 bit
    for (CDFatArch *fatArch in arches) {
        if ([fatArch maskedCPUType] == targetType && [fatArch uses64BitABI]) {
            *archPtr = [fatArch arch];
            return YES;
        }
    }
#endif

    // This architecture, 32 bit
    for (CDFatArch *fatArch in arches) {
        if ([fatArch maskedCPUType] == targetType && [fatArch uses64BitABI] == NO) {
            *archPtr = [fatArch arch];
            return YES;
        }
    }

#ifdef __LP64__
    // Any architecture, 64 bit
    for (CDFatArch *fatArch in arches) {
        if ([fatArch uses64BitABI]) {
            *archPtr = [fatArch arch];
            return YES;
        }
    }
#endif

    // Any architecture, 32 bit
    for (CDFatArch *fatArch in arches) {
        if ([fatArch uses64BitABI] == NO) {
            *archPtr = [fatArch arch];
            return YES;
        }
    }

    // Any architecture
    if ([arches count] > 0) {
        *archPtr = [[arches objectAtIndex:0] arch];
        return YES;
    }

    return NO;
}

- (CDMachOFile *)machOFileWithArch:(CDArch)cdarch;
{
    for (CDFatArch *arch in arches) {
        if ([arch cpuType] == cdarch.cputype)
            return [arch machOFile];
    }

    return nil;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%p] CDFatFile with %u arches", self, [arches count]];
}

- (NSArray *)arches;
{
    return arches;
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
