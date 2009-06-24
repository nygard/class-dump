// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import "CDSection.h"
#include <mach-o/loader.h>

@class CDDataCursor, CDMachOFile, CDLCSegment64;

@interface CDSection64 : CDSection
{
    CDLCSegment64 *nonretainedSegment;

    struct section_64 section;
}

- (id)initWithDataCursor:(CDDataCursor *)cursor segment:(CDLCSegment64 *)aSegment;

- (CDLCSegment64 *)segment;
- (CDMachOFile *)machOFile;

- (void)loadData;

- (BOOL)containsAddress:(NSUInteger)address;
- (NSUInteger)fileOffsetForAddress:(NSUInteger)address;

@end
