// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDSection64.h"

#import "CDDataCursor.h"
#import "CDMachOFile.h"

@implementation CDSection64

- (id)initWithDataCursor:(CDDataCursor *)cursor segment:(CDLCSegment64 *)aSegment;
{
    char buf[17];
    NSString *str;

    if ([super init] == nil)
        return nil;

    nonretained_segment = aSegment;

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

- (CDLCSegment64 *)segment;
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

- (void)loadData;
{
    if (_flags.hasLoadedData == NO) {
        data = [[NSData alloc] initWithBytes:[[nonretained_segment machOFile] machODataBytes] + section.offset length:section.size];
        _flags.hasLoadedData = YES;
    }
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> segment; '%@', section: '%-16s', addr: %016lx, size: %016lx",
                     NSStringFromClass([self class]), self,
                     segmentName, [sectionName UTF8String],
                     section.addr, section.size];
}

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
