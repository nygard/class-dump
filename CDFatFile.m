//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import "CDFatFile.h"

#include <mach-o/arch.h>
#import <Foundation/Foundation.h>
#import "CDFatArch.h"
#import "CDMachOFile.h"

@implementation CDFatFile

+ (id)machOFileWithFilename:(NSString *)aFilename preferredCPUType:(cpu_type_t)preferredCPUType;
{
    NSData *data;
    const uint32_t *magic;

    // TODO (2005-07-06): We're only interested in the first 4 bytes here... check how '/usr/bin/file' does it.
    data = [[NSData alloc] initWithContentsOfMappedFile:aFilename];
    if (data == nil) {
        NSLog(@"Couldn't map file: %@", aFilename);
        return nil;
    }

    magic = [data bytes];
    if (*magic == FAT_MAGIC) {
        CDFatFile *fatFile;
        CDFatArch *fatArch;

        [data release];
        NSLog(@"CDFatFile: Fat file...");
        fatFile = [[[CDFatFile alloc] initWithFilename:aFilename] autorelease];
        fatArch = [fatFile fatArchWithPreferredCPUType:preferredCPUType];
        return [[[CDMachOFile alloc] initWithFilename:aFilename archiveOffset:[fatArch offset]] autorelease];
    }

    [data release];

    NSLog(@"Trying regular mach-o file.");
    return [[[CDMachOFile alloc] initWithFilename:aFilename] autorelease];
}

- (id)initWithFilename:(NSString *)aFilename;
{
    if ([super init] == nil)
        return nil;

    filename = [aFilename retain];
    data = [[NSData alloc] initWithContentsOfMappedFile:filename];
    if (data == nil) {
        NSLog(@"Couldn't read file: %@", filename);
        [filename release];
        [self release];
        return nil;
    }

    header = [data bytes];
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

- (CDFatArch *)fatArchWithPreferredCPUType:(cpu_type_t)preferredCPUType;
{
    NSLog(@"Looking for cpu type: %d", preferredCPUType);
    if (preferredCPUType == CPU_TYPE_ANY) {
        const NXArchInfo *archInfo;
        CDFatArch *fatArch;

        // Look first for the local architecture.  If not found, just pick the first one.
        archInfo = NXGetLocalArchInfo();
        NSLog(@"Looking first for local arch, archInfo: %p, arch: %d", archInfo, archInfo->cputype);
        fatArch = [self fatArchWithCPUType:archInfo->cputype];
        if (fatArch == nil && [arches count] > 0) {
            NSLog(@"Couldn't find preferred type, picking first available arch.");
            fatArch = [arches objectAtIndex:0];
        }

        NSLog(@"fatArch: %@", fatArch);
        return fatArch;
    }

    return [self fatArchWithCPUType:preferredCPUType];
}

- (CDFatArch *)fatArchWithCPUType:(cpu_type_t)aCPUType;
{
    unsigned int count, index;

    count = [arches count];
    for (index = 0; index < count; index++) {
        CDFatArch *fatArch;

        fatArch = [arches objectAtIndex:index];
        if ([fatArch cpuType] == aCPUType)
            return fatArch;
    }

    return nil;
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
