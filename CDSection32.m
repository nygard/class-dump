// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDSection32.h"

#import "CDFatFile.h"
#import "CDMachOFile.h"
#import "CDLCSegment32.h"

@implementation CDSection32

// Just to resolve multiple different definitions...
- (id)initWithDataCursor:(CDDataCursor *)cursor segment:(CDLCSegment32 *)aSegment;
{
    char buf[17];
    NSString *str;

    if ([super init] == nil)
        return nil;

    nonretained_segment = aSegment;

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
    str = [[NSString alloc] initWithBytes:buf length:strlen(buf) encoding:NSASCIIStringEncoding];
    [self setSegmentName:str];
    [str release];

    memcpy(buf, section.sectname, 16);
    buf[16] = 0;
    str = [[NSString alloc] initWithBytes:buf length:strlen(buf) encoding:NSASCIIStringEncoding];
    [self setSectionName:str];
    [str release];

    return self;
}

- (CDLCSegment32 *)segment;
{
    return nonretained_segment;
}

- (CDMachOFile *)machOFile;
{
    return [[self segment] machOFile];
}

- (NSUInteger)addr;
{
    return section.addr;
}

- (NSUInteger)size;
{
    return section.size;
}

- (uint32_t)offset;
{
    return section.offset;
}

- (void)loadData;
{
    if (_flags.hasLoadedData == NO) {
        data = [[NSData alloc] initWithBytes:[[nonretained_segment machOFile] machODataBytes] + section.offset length:section.size];
        _flags.hasLoadedData = YES;
    }
}

#if 1
- (NSString *)description;
{
    return [NSString stringWithFormat:@"addr: 0x%08x, offset: %8d, size: %8d [0x%8x], segment; '%@', section: '%@'",
                     section.addr, section.offset, section.size, section.size, segmentName, sectionName];
}
#endif

- (BOOL)containsAddress:(NSUInteger)address;
{
    return (address >= section.addr) && (address < section.addr + section.size);
}

- (NSUInteger)fileOffsetForAddress:(NSUInteger)address;
{
    NSParameterAssert([self containsAddress:address]);
    return section.offset + address - section.addr;
}

@end
