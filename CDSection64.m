// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import "CDSection64.h"

#import "CDDataCursor.h"

@implementation CDSection64

- (id)initWithDataCursor:(CDDataCursor *)cursor segment:(CDLCSegment64 *)aSegment;
{
    char buf[17];

    if ([super init] == nil)
        return nil;

    nonretainedSegment = aSegment;

    [cursor readBytesOfLength:16 intoBuffer:section.sectname];
    [cursor readBytesOfLength:16 intoBuffer:section.segname];
    section.addr = [cursor readInt64];
    section.size = [cursor readInt64];
    section.offset = [cursor readInt32];
    section.align = [cursor readInt32];
    section.reloff = [cursor readInt32];
    section.nreloc = [cursor readInt32];
    section.flags = [cursor readInt32];
    section.reserved1 = [cursor readInt32];
    section.reserved2 = [cursor readInt32];
    section.reserved3 = [cursor readInt32];

    // These aren't guaranteed to be null terminated.  Witness __cstring_object in __OBJC segment

    memcpy(buf, section.segname, 16);
    buf[16] = 0;
    segmentName = [[NSString alloc] initWithBytes:buf length:strlen(buf) encoding:NSASCIIStringEncoding];

    memcpy(buf, section.sectname, 16);
    buf[16] = 0;
    sectionName = [[NSString alloc] initWithBytes:buf length:strlen(buf) encoding:NSASCIIStringEncoding];

    //NSLog(@"segmentName: '%@', sectionName: '%@'", segmentName, sectionName);

    return self;
}

- (void)dealloc;
{
    [segmentName release];
    [sectionName release];

    [super dealloc];
}

- (CDLCSegment64 *)segment;
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

@end
