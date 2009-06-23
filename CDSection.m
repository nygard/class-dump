// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import "CDSection.h"

#include <mach-o/swap.h>
#import "CDFatFile.h"
#import "CDMachOFile.h"
#import "CDLCSegment32.h"

@implementation CDSection

// Just to resolve multiple different definitions...
- (id)initWithDataCursor:(CDDataCursor *)cursor segment:(CDLCSegment32 *)aSegment;
{
    char buf[17];

    if ([super init] == nil)
        return nil;

    nonretainedSegment = aSegment;

    [cursor readBytesOfLength:16 intoBuffer:section.sectname];
    [cursor readBytesOfLength:16 intoBuffer:section.segname];
    section.addr = [cursor readInt32];
    section.size = [cursor readInt32];
    section.offset = [cursor readInt32];
    section.align = [cursor readInt32];
    section.reloff = [cursor readInt32];
    section.nreloc = [cursor readInt32];
    section.flags = [cursor readInt32];
    section.reserved1 = [cursor readInt32];
    section.reserved2 = [cursor readInt32];

    // These aren't guaranteed to be null terminated.  Witness __cstring_object in __OBJC segment

    memcpy(buf, section.segname, 16);
    buf[16] = 0;
    segmentName = [[NSString alloc] initWithBytes:buf length:strlen(buf) encoding:NSASCIIStringEncoding];

    memcpy(buf, section.sectname, 16);
    buf[16] = 0;
    sectionName = [[NSString alloc] initWithBytes:buf length:strlen(buf) encoding:NSASCIIStringEncoding];

    //NSLog(@"segmentName: '%@', sectionName: '%@'", segmentName, sectionName);

    data = nil;
    _flags.hasLoadedData = NO;

    return self;
}

- (void)dealloc;
{
    [segmentName release];
    [sectionName release];
    [data release];

    [super dealloc];
}

- (CDLCSegment32 *)segment;
{
    return nonretainedSegment;
}

- (CDMachOFile *)machOFile;
{
    return [[self segment] machOFile];
}

- (NSString *)segmentName;
{
    return segmentName;
}

- (NSString *)sectionName;
{
    return sectionName;
}

- (uint32_t)addr;
{
    return section.addr;
}

- (uint32_t)size;
{
    return section.size;
}

- (uint32_t)offset;
{
    return section.offset;
}

- (NSData *)data;
{
    if (_flags.hasLoadedData == NO) {
        data = [[NSData alloc] initWithBytes:[[nonretainedSegment machOFile] machODataBytes] + section.offset length:section.size];
        _flags.hasLoadedData = YES;
    }

    return data;
}

- (void)unloadData;
{
    if (_flags.hasLoadedData) {
        _flags.hasLoadedData = NO;
        [data release];
        data = nil;
    }
}

- (const void *)dataPointer;
{
    return [[self machOFile] bytes] + section.offset;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"addr: 0x%08x, offset: %8d, size: %8d [0x%8x], segment; '%@', section: '%@'",
                     section.addr, section.offset, section.size, section.size, segmentName, sectionName];
}

- (BOOL)containsAddress:(uint32_t)address;
{
    // TODO (2003-12-06): And what happens when the filesize of the segment is less than the vmsize?
    return (address >= section.addr) && (address < section.addr + section.size);
}

- (uint32_t)fileOffsetForAddress:(uint32_t)address;
{
    NSParameterAssert([self containsAddress:address]);
    return section.offset + address - section.addr;
}

@end
