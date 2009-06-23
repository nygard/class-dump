// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import "CDSegment64.h"

#import "CDSection64.h"
#import "CDDataCursor.h"

@implementation CDSegment64

- (id)initWithDataCursor:(CDDataCursor *)cursor machOFile:(CDMachOFile *)aMachOFile;
{
    if ([super initWithDataCursor:cursor machOFile:aMachOFile] == nil)
        return nil;

    segmentCommand.cmd = [cursor readInt32];
    segmentCommand.cmdsize = [cursor readInt32];

    [cursor readBytesOfLength:16 intoBuffer:segmentCommand.segname];
    segmentCommand.vmaddr = [cursor readInt64];
    segmentCommand.vmsize = [cursor readInt64];
    segmentCommand.fileoff = [cursor readInt64];
    segmentCommand.filesize = [cursor readInt64];
    segmentCommand.maxprot = [cursor readInt32];
    segmentCommand.initprot = [cursor readInt32];
    segmentCommand.nsects = [cursor readInt32];
    segmentCommand.flags = [cursor readInt32];

    {
        char buf[17];

        memcpy(buf, segmentCommand.segname, 16);
        buf[16] = 0;
        name = [[NSString alloc] initWithBytes:buf length:strlen(buf) encoding:NSASCIIStringEncoding];
        if ([name length] >= 16) {
            NSLog(@"Notice: segment '%@' has length >= 16, which means it's not always null terminated.", name);
        }
    }

    {
        unsigned int index;

        sections = [[NSMutableArray alloc] init];
        for (index = 0; index < segmentCommand.nsects; index++) {
            CDSection64 *section;

            section = [[CDSection64 alloc] initWithDataCursor:cursor segment:self];
            [sections addObject:section];
            [section release];
        }
    }

    return self;
}

- (void)dealloc;
{
    [name release];
    [sections release];

    [super dealloc];
}

- (uint32_t)cmd;
{
    return segmentCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return segmentCommand.cmdsize;
}

@end
