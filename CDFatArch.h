// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2007  Steve Nygard

#import <Foundation/NSObject.h>

#include <mach-o/fat.h>

@class CDDataCursor;
@class CDMachOFile;

@interface CDFatArch : NSObject
{
    struct fat_arch fatArch;

    BOOL uses64BitABI;

    //CDMachOFile *machOFile; // Lazily create this.
}

- (id)initWithDataCursor:(CDDataCursor *)cursor;
- (void)dealloc;

- (cpu_type_t)cpuType;
- (cpu_subtype_t)cpuSubtype;
- (uint32_t)offset;
- (uint32_t)size;
- (uint32_t)align;

- (BOOL)uses64BitABI;

- (NSString *)description;

- (NSString *)archName;

- (CDMachOFile *)machOFile;

@end
