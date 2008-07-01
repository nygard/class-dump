//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2007  Steve Nygard

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

    if ([cursor readBigInt32:(uint32_t *)&cputype] == NO) {
        NSLog(@"cputype read failed");
        [self release];
        return nil;
    }

    if ([cursor readBigInt32:(uint32_t *)&cpusubtype] == NO) {
        NSLog(@"cpu subtype read failed");
        [self release];
        return nil;
    }

    if ([cursor readBigInt32:&offset] == NO) {
        NSLog(@"size offset failed");
        [self release];
        return nil;
    }

    if ([cursor readBigInt32:&size] == NO) {
        NSLog(@"size read failed");
        [self release];
        return nil;
    }

    if ([cursor readBigInt32:&align] == NO) {
        NSLog(@"align read failed");
        [self release];
        return nil;
    }

    uses64BitABI = (cputype & CPU_ARCH_MASK) == CPU_ARCH_ABI64;
    cputype &= ~CPU_ARCH_MASK;
#if 0
    NSLog(@"type: 64 bit? %d, 0x%x, subtype: 0x%x, offset: 0x%x, size: 0x%x, align: 0x%x",
          uses64BitABI, cputype, cpusubtype, offset, size, align);
#endif
    return self;
}

- (void)dealloc;
{
    [super dealloc];
}

- (cpu_type_t)cpuType;
{
    return cputype;
}

- (cpu_subtype_t)cpuSubtype;
{
    return cpusubtype;
}

- (uint32_t)offset;
{
    return offset;
}

- (uint32_t)size;
{
    return size;
}

- (uint32_t)align;
{
    return align;
}

- (BOOL)uses64BitABI;
{
    return uses64BitABI;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"64 bit ABI? %d, cputype: 0x%08x, cpusubtype: 0x%08x, offset: 0x%08x (%8u), size: 0x%08x (%8u), align: 2^%d (%d), arch name: %@",
                     uses64BitABI, cputype, cpusubtype, offset, offset, size, size, align, 1<<align, [self archName]];
}

// Must not return nil.
- (NSString *)archName;
{
    if (uses64BitABI)
        return CDNameForCPUType(cputype | CPU_ARCH_ABI64, cpusubtype);

    return CDNameForCPUType(cputype, cpusubtype);
}

@end
