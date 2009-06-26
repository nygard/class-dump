// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import "CDFatArch.h"

#import <mach-o/swap.h>
#import <Foundation/Foundation.h>
#import "CDDataCursor.h"
#import "CDFatFile.h"
#import "CDMachOFile.h"

@implementation CDFatArch

- (id)initWithDataCursor:(CDDataCursor *)cursor;
{
    if ([super init] == nil)
        return nil;

    nonretainedFatFile = nil;

    fatArch.cputype = [cursor readBigInt32];
    fatArch.cpusubtype = [cursor readBigInt32];
    fatArch.offset = [cursor readBigInt32];
    fatArch.size = [cursor readBigInt32];
    fatArch.align = [cursor readBigInt32];

    uses64BitABI = (fatArch.cputype & CPU_ARCH_MASK) == CPU_ARCH_ABI64;
    //fatArch.cputype &= ~CPU_ARCH_MASK;
#if 0
    NSLog(@"type: 64 bit? %d, 0x%x, subtype: 0x%x, offset: 0x%x, size: 0x%x, align: 0x%x",
          uses64BitABI, fatArch.cputype, fatArch.cpusubtype, fatArch.offset, fatArch.size, fatArch.align);
#endif

    machOFile = nil;

    return self;
}

- (void)dealloc;
{
    [machOFile release];

    [super dealloc];
}

- (cpu_type_t)cpuType;
{
    return fatArch.cputype;
}

- (cpu_type_t)maskedCPUType;
{
    return fatArch.cputype & ~CPU_ARCH_MASK;
}

- (cpu_subtype_t)cpuSubtype;
{
    return fatArch.cpusubtype;
}

- (uint32_t)offset;
{
    return fatArch.offset;
}

- (uint32_t)size;
{
    return fatArch.size;
}

- (uint32_t)align;
{
    return fatArch.align;
}

- (BOOL)uses64BitABI;
{
    return uses64BitABI;
}

- (CDFatFile *)fatFile;
{
    return nonretainedFatFile;
}

- (void)setFatFile:(CDFatFile *)newFatFile;
{
    nonretainedFatFile = [newFatFile retain];
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"64 bit ABI? %d, cputype: 0x%08x, cpusubtype: 0x%08x, offset: 0x%08x (%8u), size: 0x%08x (%8u), align: 2^%d (%d), arch name: %@",
                     uses64BitABI, fatArch.cputype, fatArch.cpusubtype, fatArch.offset, fatArch.offset, fatArch.size, fatArch.size,
                     fatArch.align, 1 << fatArch.align, [self archName]];
}

// Must not return nil.
- (NSString *)archName;
{
#if 0
    if (uses64BitABI)
        return CDNameForCPUType(fatArch.cputype | CPU_ARCH_ABI64, fatArch.cpusubtype);
#endif
    return CDNameForCPUType(fatArch.cputype, fatArch.cpusubtype);
}

- (CDMachOFile *)machOFile;
{
    if (machOFile == nil) {
        //NSLog(@"nonretainedFatFile: %p", nonretainedFatFile);
        //NSLog(@"nrff data: %p", [nonretainedFatFile data]);
        machOFile = [[CDFile fileWithData:[nonretainedFatFile data] offset:fatArch.offset] retain];
        [machOFile setFilename:[nonretainedFatFile filename]];
    }

    return machOFile;
}

@end
