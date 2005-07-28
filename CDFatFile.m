//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import "CDFatFile.h"

#include <mach-o/arch.h>
#import <Foundation/Foundation.h>
#import "CDFatArch.h"
#import "CDMachOFile.h"

// The fat_header and fat_arch structures are stored in big endian-byte order.
// TODO (2005-07-27): For Intel, we'll need to swap those structs.

@implementation CDFatFile

- (id)initWithFilename:(NSString *)aFilename;
{
    if ([super init] == nil)
        return nil;

    filename = [aFilename retain];

    data = [[NSData alloc] initWithContentsOfMappedFile:filename];
    if (data == nil) {
        NSLog(@"Couldn't read file: %@", filename);
        [self release];
        return nil;
    }

    header = [data bytes];
    if (header->magic != CD_FAT_MAGIC) {
        [self release];
        return nil;
    }

    arches = [[NSMutableArray alloc] init];
    [self _processFatArches];

    return self;
}

- (void)dealloc;
{
    [filename release];
    [data release];
    [arches release];

    [super dealloc];
}

- (void)_processFatArches;
{
    unsigned int count, index;
    const struct fat_arch *ptr;

    ptr = (struct fat_arch *)(header + 1);

    count = [self fatCount];
    for (index = 0; index < count; index++) {
        CDFatArch *fatArch;

        fatArch = [[CDFatArch alloc] initWithPointer:ptr];
        [arches addObject:fatArch];
        [fatArch release];
        ptr++;
    }
}

- (NSString *)filename;
{
    return filename;
}

- (unsigned int)fatCount;
{
    return header->nfat_arch;
}

- (CDFatArch *)fatArchWithCPUType:(cpu_type_t)aCPUType;
{
    if (aCPUType == CPU_TYPE_ANY) {
        CDFatArch *fatArch;

        fatArch = [self localArchitecture];
        if (fatArch == nil && [arches count] > 0)
            fatArch = [arches objectAtIndex:0];

        return fatArch;
    }

    return [self _fatArchWithCPUType:aCPUType];
}

- (CDFatArch *)_fatArchWithCPUType:(cpu_type_t)aCPUType;
{
    unsigned int count, index;

    assert(aCPUType != CPU_TYPE_ANY);
    count = [arches count];
    for (index = 0; index < count; index++) {
        CDFatArch *fatArch;

        fatArch = [arches objectAtIndex:index];
        if ([fatArch cpuType] == aCPUType)
            return fatArch;
    }

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

    NSLog(@"Local arch: %d, %s (%s)", archInfo->cputype, archInfo->description, archInfo->name);

    return [self _fatArchWithCPUType:archInfo->cputype];
}

- (NSString *)description;
{
    return @"fat file...";
#if 0
    return [NSString stringWithFormat:@"magic: 0x%08x, cputype: %d, cpusubtype: %d, filetype: %d, ncmds: %d, sizeofcmds: %d, flags: 0x%x",
                     header->magic, header->cputype, header->cpusubtype, header->filetype, header->ncmds, header->sizeofcmds, header->flags];
#endif
}

@end
