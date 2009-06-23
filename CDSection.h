// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import <Foundation/Foundation.h>
#include <mach-o/loader.h>

@class CDDataCursor, CDMachOFile, CDLCSegment32;

@interface CDSection : NSObject
{
    CDLCSegment32 *nonretainedSegment;

    struct section section;
    NSString *segmentName;
    NSString *sectionName;

    NSData *data;
    struct {
        unsigned int hasLoadedData:1;
    } _flags;
}

- (id)initWithDataCursor:(CDDataCursor *)cursor segment:(CDLCSegment32 *)aSegment;
- (void)dealloc;

- (CDLCSegment32 *)segment;
- (CDMachOFile *)machOFile;

- (NSString *)segmentName;
- (NSString *)sectionName;
- (uint32_t)addr;
- (uint32_t)size;
- (uint32_t)offset;

- (NSData *)data;
- (void)unloadData;

- (const void *)dataPointer; // Has no access to the mach-o file

- (NSString *)description;

- (BOOL)containsAddress:(uint32_t)address;
- (uint32_t)fileOffsetForAddress:(uint32_t)address;

@end
