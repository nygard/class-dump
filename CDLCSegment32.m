// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDLCSegment32.h"

#import "CDDataCursor.h"
#import "CDSection32.h"

@implementation CDLCSegment32

- (id)initWithDataCursor:(CDDataCursor *)cursor machOFile:(CDMachOFile *)aMachOFile;
{
    if ([super initWithDataCursor:cursor machOFile:aMachOFile] == nil)
        return nil;

    segmentCommand.cmd = [cursor readInt32];
    segmentCommand.cmdsize = [cursor readInt32];

    [cursor readBytesOfLength:16 intoBuffer:segmentCommand.segname];
    segmentCommand.vmaddr = [cursor readInt32];
    segmentCommand.vmsize = [cursor readInt32];
    segmentCommand.fileoff = [cursor readInt32];
    segmentCommand.filesize = [cursor readInt32];
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
            CDSection32 *section;

            section = [[CDSection32 alloc] initWithDataCursor:cursor segment:self];
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

- (NSString *)extraDescription;
{
#if 1
    return [NSString stringWithFormat:@"vmaddr: 0x%08x - 0x%08x [0x%08x], offset: %d, flags: 0x%x (%@), nsects: %d, sections: %@",
                     segmentCommand.vmaddr, segmentCommand.vmaddr + segmentCommand.vmsize - 1, segmentCommand.vmsize, segmentCommand.fileoff,
                     [self flags], [self flagDescription], segmentCommand.nsects, sections];
#endif
    return nil;
}

- (BOOL)containsAddress:(NSUInteger)address;
{
    return (address >= segmentCommand.vmaddr) && (address < segmentCommand.vmaddr + segmentCommand.vmsize);
}

- (void)appendToString:(NSMutableString *)resultString verbose:(BOOL)isVerbose;
{
    [super appendToString:resultString verbose:isVerbose];
#if 0

    [resultString appendFormat:@"  segname %@\n", [self name]];
    [resultString appendFormat:@"   vmaddr 0x%08x\n", segmentCommand.vmaddr];
    [resultString appendFormat:@"   vmsize 0x%08x\n", segmentCommand.vmsize];
    [resultString appendFormat:@"  fileoff %d\n", segmentCommand.fileoff];
    [resultString appendFormat:@" filesize %d\n", segmentCommand.filesize];
    [resultString appendFormat:@"  maxprot 0x%08x\n", segmentCommand.maxprot];
    [resultString appendFormat:@" initprot 0x%08x\n", segmentCommand.initprot];
    [resultString appendFormat:@"   nsects %d\n", segmentCommand.nsects];

    if (isVerbose)
        [resultString appendFormat:@"    flags %@\n", [self flagDescription]];
    else
        [resultString appendFormat:@"    flags 0x%x\n", segmentCommand.flags];
#endif
}

@end
