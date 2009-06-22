// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2009 Steve Nygard.  All rights reserved.

#import "CDMachOFile.h"

@interface CDMachO32File : CDMachOFile
{
    struct mach_header header; // header.magic is read in and stored in little endian order.(?)
}

- (id)initWithData:(NSData *)_data;

- (uint32_t)magic;
- (cpu_type_t)cputype;
- (cpu_subtype_t)cpusubtype;
- (uint32_t)filetype;
- (uint32_t)flags;

- (NSString *)bestMatchForLocalArch;

@end
