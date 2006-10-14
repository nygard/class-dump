//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2006  Steve Nygard

#import "CDFatArch.h"

#import <mach-o/swap.h>
#import <Foundation/Foundation.h>
#import "CDFatFile.h"
#import "CDMachOFile.h"

@implementation CDFatArch

- (id)initWithPointer:(const void *)ptr swapBytes:(BOOL)shouldSwapBytes;
{
    if ([super init] == nil)
        return nil;

    arch = *(struct fat_arch *)ptr;
    if (shouldSwapBytes == YES)
        swap_fat_arch(&arch, 1, CD_THIS_BYTE_ORDER);

    return self;
}

- (void)dealloc;
{
    [super dealloc];
}

- (cpu_type_t)cpuType;
{
    return arch.cputype;
}

- (cpu_subtype_t)cpuSubtype;
{
    return arch.cpusubtype;
}

- (uint32_t)offset;
{
    return arch.offset;
}

- (uint32_t)size;
{
    return arch.size;
}

- (uint32_t)align;
{
    return arch.align;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"cputype: %d, cpusubtype: %d, offset: 0x%x, size: 0x%x, align: %d",
                     arch.cputype, arch.cpusubtype, arch.offset, arch.size, arch.align];
}

@end
