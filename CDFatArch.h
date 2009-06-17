// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2007  Steve Nygard

#import <Foundation/NSObject.h>

@class CDDataCursor;
@class CDMachOFile;

@interface CDFatArch : NSObject
{
    cpu_type_t cputype;
    cpu_subtype_t cpusubtype;
    uint32_t offset;
    uint32_t size;
    uint32_t align;

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
