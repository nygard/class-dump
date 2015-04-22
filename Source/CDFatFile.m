// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDFatFile.h"

#include <mach-o/arch.h>
#include <mach-o/fat.h>

#import "CDDataCursor.h"
#import "CDFatArch.h"
#import "CDMachOFile.h"

@implementation CDFatFile
{
    NSMutableArray *_arches;
}

- (id)init;
{
    if ((self = [super init])) {
        _arches = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (id)initWithData:(NSData *)data filename:(NSString *)filename searchPathState:(CDSearchPathState *)searchPathState;
{
    if ((self = [super initWithData:data filename:filename searchPathState:searchPathState])) {
        CDDataCursor *cursor = [[CDDataCursor alloc] initWithData:data];

        struct fat_header header;
        header.magic = [cursor readBigInt32];
        
        //NSLog(@"(testing fat) magic: 0x%x", header.magic);
        if (header.magic != FAT_MAGIC) {
            return nil;
        }
        
        _arches = [[NSMutableArray alloc] init];
        
        header.nfat_arch = [cursor readBigInt32];
        //NSLog(@"nfat_arch: %u", header.nfat_arch);
        for (NSUInteger index = 0; index < header.nfat_arch; index++) {
            CDFatArch *arch = [[CDFatArch alloc] initWithDataCursor:cursor];
            arch.fatFile = self;
            [_arches addObject:arch];
        }
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> %lu arches", NSStringFromClass([self class]), self, [self.arches count]];
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
- (BOOL)bestMatchForArch:(CDArch *)ioArchPtr;
{
    cpu_type_t targetType = ioArchPtr->cputype & ~CPU_ARCH_MASK;

    // Target architecture, 64 bit
    for (CDFatArch *fatArch in self.arches) {
        if (fatArch.maskedCPUType == targetType && fatArch.uses64BitABI) {
            if (ioArchPtr != NULL) *ioArchPtr = fatArch.arch;
            return YES;
        }
    }

    // Target architecture, 32 bit
    for (CDFatArch *fatArch in self.arches) {
        if (fatArch.maskedCPUType == targetType && fatArch.uses64BitABI == NO) {
            if (ioArchPtr != NULL) *ioArchPtr = fatArch.arch;
            return YES;
        }
    }

    // Any architecture, 64 bit
    for (CDFatArch *fatArch in self.arches) {
        if (fatArch.uses64BitABI) {
            if (ioArchPtr != NULL) *ioArchPtr = fatArch.arch;
            return YES;
        }
    }

    // Any architecture, 32 bit
    for (CDFatArch *fatArch in self.arches) {
        if (fatArch.uses64BitABI == NO) {
            if (ioArchPtr != NULL) *ioArchPtr = fatArch.arch;
            return YES;
        }
    }

    // Any architecture
    if ([self.arches count] > 0) {
        if (ioArchPtr != NULL) *ioArchPtr = [self.arches[0] arch];
        return YES;
    }

    return NO;
}

- (CDFatArch *)fatArchWithArch:(CDArch)cdarch;
{
    for (CDFatArch *arch in self.arches) {
        if (arch.cputype == cdarch.cputype && arch.maskedCPUSubtype == (cdarch.cpusubtype & ~CPU_SUBTYPE_MASK))
            return arch;
    }

    return nil;
}

- (CDMachOFile *)machOFileWithArch:(CDArch)cdarch;
{
    return [[self fatArchWithArch:cdarch] machOFile];
}

- (NSArray *)archNames;
{
    NSMutableArray *archNames = [NSMutableArray array];
    for (CDFatArch *arch in self.arches)
        [archNames addObject:arch.archName];

    return archNames;
}

- (NSString *)architectureNameDescription;
{
    return [self.archNames componentsJoinedByString:@", "];
}

#pragma mark -

- (void)addArchitecture:(CDFatArch *)fatArch;
{
    fatArch.fatFile = self;
    [self.arches addObject:fatArch];
}

- (BOOL)containsArchitecture:(CDArch)arch;
{
    return [self fatArchWithArch:arch] != nil;
}

@end
