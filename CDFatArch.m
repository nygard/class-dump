// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDFatArch.h"

#import "CDDataCursor.h"
#import "CDFatFile.h"
#import "CDMachOFile.h"

@implementation CDFatArch

- (id)initWithDataCursor:(CDDataCursor *)cursor;
{
    if ([super init] == nil)
        return nil;

    nonretained_fatFile = nil;

    fatArch.cputype = [cursor readBigInt32];
    fatArch.cpusubtype = [cursor readBigInt32];
    fatArch.offset = [cursor readBigInt32];
    fatArch.size = [cursor readBigInt32];
    fatArch.align = [cursor readBigInt32];

#if 0
    NSLog(@"type: 64 bit? %d, 0x%x, subtype: 0x%x, offset: 0x%x, size: 0x%x, align: 0x%x",
          [self uses64BitABI], fatArch.cputype, fatArch.cpusubtype, fatArch.offset, fatArch.size, fatArch.align);
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
    return CDArchUses64BitABI((CDArch){ .cputype = fatArch.cputype, .cpusubtype = fatArch.cpusubtype });
}

- (CDFatFile *)fatFile;
{
    return nonretained_fatFile;
}

- (void)setFatFile:(CDFatFile *)newFatFile;
{
    nonretained_fatFile = [newFatFile retain];
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"64 bit ABI? %d, cputype: 0x%08x, cpusubtype: 0x%08x, offset: 0x%08x (%8u), size: 0x%08x (%8u), align: 2^%d (%d), arch name: %@",
                     [self uses64BitABI], fatArch.cputype, fatArch.cpusubtype, fatArch.offset, fatArch.offset, fatArch.size, fatArch.size,
                     fatArch.align, 1 << fatArch.align, [self archName]];
}

- (CDArch)arch;
{
    CDArch arch;

    arch.cputype = fatArch.cputype;
    arch.cpusubtype = fatArch.cpusubtype;

    return arch;
}

// Must not return nil.
- (NSString *)archName;
{
    return CDNameForCPUType(fatArch.cputype, fatArch.cpusubtype);
}

- (CDMachOFile *)machOFile;
{
    if (machOFile == nil) {
        machOFile = [[CDFile fileWithData:[nonretained_fatFile data] offset:fatArch.offset filename:[nonretained_fatFile filename] searchPathState:[nonretained_fatFile searchPathState]] retain];
    }

    return machOFile;
}

- (NSData *)machOData;
{
    return [[[NSData alloc] initWithBytes:[[nonretained_fatFile data] bytes] + fatArch.offset length:fatArch.size] autorelease];
}

@end
