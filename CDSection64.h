// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2011 Steve Nygard.

#import "CDSection.h"
#include <mach-o/loader.h>

@class CDMachOFileDataCursor, CDMachOFile, CDLCSegment64;

@interface CDSection64 : CDSection
{
    CDLCSegment64 *nonretained_segment;

    struct section_64 section;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor segment:(CDLCSegment64 *)aSegment;

- (NSString *)description;

@property (readonly) CDLCSegment64 *segment;

- (void)loadData;

- (BOOL)containsAddress:(NSUInteger)address;
- (NSUInteger)fileOffsetForAddress:(NSUInteger)address;

@end
