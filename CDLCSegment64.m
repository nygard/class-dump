// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDLCSegment64.h"

#import "CDSection64.h"
#import "CDDataCursor.h"

@implementation CDLCSegment64

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
        NSString *str;

        memcpy(buf, segmentCommand.segname, 16);
        buf[16] = 0;
        str = [[NSString alloc] initWithBytes:buf length:strlen(buf) encoding:NSASCIIStringEncoding];
        if ([str length] >= 16) {
            NSLog(@"Notice: segment '%@' has length >= 16, which means it's not always null terminated.", str);
        }
        [self setName:str];
        [str release];
    }

    {
        unsigned int index;

        for (index = 0; index < segmentCommand.nsects; index++) {
            CDSection64 *section;

            section = [[CDSection64 alloc] initWithDataCursor:cursor segment:self];
            [sections addObject:section];
            [section release];
        }
    }

    return self;
}

- (uint32_t)cmd;
{
    return segmentCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return segmentCommand.cmdsize;
}

- (NSUInteger)vmaddr;
{
    return segmentCommand.vmaddr;
}

- (NSUInteger)fileoff;
{
    return segmentCommand.fileoff;
}

- (NSUInteger)filesize;
{
    return segmentCommand.filesize;
}

- (vm_prot_t)initprot;
{
    return segmentCommand.initprot;
}

- (uint32_t)flags;
{
    return segmentCommand.flags;
}

- (BOOL)containsAddress:(NSUInteger)address;
{
    return (address >= segmentCommand.vmaddr) && (address < segmentCommand.vmaddr + segmentCommand.vmsize);
}

- (NSString *)extraDescription;
{
    return [NSString stringWithFormat:@"addr: 0x%016lx", [self vmaddr]];
}

@end
