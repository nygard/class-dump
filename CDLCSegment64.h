// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDLCSegment.h"

@interface CDLCSegment64 : CDLCSegment
{
    struct segment_command_64 segmentCommand;
}

- (id)initWithDataCursor:(CDDataCursor *)cursor machOFile:(CDMachOFile *)aMachOFile;

- (uint32_t)cmd;
- (uint32_t)cmdsize;

- (NSUInteger)vmaddr;
- (NSUInteger)fileoff;
- (NSUInteger)filesize;
- (vm_prot_t)initprot;
- (uint32_t)flags;

- (BOOL)containsAddress:(NSUInteger)address;

- (NSString *)extraDescription;

@end
