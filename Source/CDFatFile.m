// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDFatFile.h"

#include <mach-o/arch.h>
#include <mach-o/fat.h>

#import "CDDataCursor.h"
#import "CDFatArch.h"
#import "CDMachOFile.h"

@implementation CDFatFile
{
    NSArray *arches;
}

- (id)initWithData:(NSData *)someData archOffset:(NSUInteger)anOffset archSize:(NSUInteger)aSize filename:(NSString *)aFilename searchPathState:(CDSearchPathState *)aSearchPathState;
{
    if ((self = [super initWithData:someData archOffset:anOffset archSize:aSize filename:aFilename searchPathState:aSearchPathState])) {
        CDDataCursor *cursor = [[CDDataCursor alloc] initWithData:someData offset:self.archOffset];

        struct fat_header header;
        header.magic = [cursor readBigInt32];
        
        //NSLog(@"(testing fat) magic: 0x%x", header.magic);
        if (header.magic != FAT_MAGIC) {
            return nil;
        }
        
        NSMutableArray *_arches = [[NSMutableArray alloc] init];
        
        header.nfat_arch = [cursor readBigInt32];
        //NSLog(@"nfat_arch: %u", header.nfat_arch);
        for (unsigned int index = 0; index < header.nfat_arch; index++) {
            CDFatArch *arch = [[CDFatArch alloc] initWithDataCursor:cursor];
            [arch setFatFile:self];
            [_arches addObject:arch];
        }
        arches = [_arches copy];
        //NSLog(@"arches: %@", arches);
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%p] CDFatFile with %u arches", self, [arches count]];
}

#pragma mark -


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
    const NXArchInfo *archInfo = NXGetLocalArchInfo();
    if (archInfo == NULL)
        return NO;

    if (archPtr == NULL)
        return [arches count] > 0;

    cpu_type_t targetType = archInfo->cputype & ~CPU_ARCH_MASK;

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

- (NSArray *)arches;
{
    return arches;
}

- (NSArray *)archNames;
{
    NSMutableArray *archNames = [NSMutableArray array];
    for (CDFatArch *arch in arches)
        [archNames addObject:[arch archName]];

    return archNames;
}

@end
