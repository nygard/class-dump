// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDMachOFile.h"

@interface CDMachO32File : CDMachOFile
{
    struct mach_header header; // header.magic is read in and stored in little endian order.
}

- (id)initWithData:(NSData *)someData offset:(NSUInteger)anOffset filename:(NSString *)aFilename searchPathState:(CDSearchPathState *)aSearchPathState;

- (uint32_t)magic;
- (cpu_type_t)cputype;
- (cpu_subtype_t)cpusubtype;
- (uint32_t)filetype;
- (uint32_t)flags;

- (BOOL)bestMatchForLocalArch:(CDArch *)archPtr;

- (Class)processorClass;

@end
