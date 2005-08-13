//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2005  Steve Nygard

#import <Foundation/NSObject.h>
#include <mach-o/fat.h>

@interface CDFatArch : NSObject
{
    struct fat_arch arch;
}

- (id)initWithPointer:(const void *)ptr swapBytes:(BOOL)shouldSwapBytes;
- (void)dealloc;

- (cpu_type_t)cpuType;
- (cpu_subtype_t)cpuSubtype;
- (uint32_t)offset;
- (uint32_t)size;
- (uint32_t)align;

- (NSString *)description;

@end
