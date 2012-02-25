// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDSection32.h"

#include <mach-o/loader.h>
#import "CDFatFile.h"
#import "CDMachOFile.h"
#import "CDLCSegment32.h"

@implementation CDSection32
{
    __weak CDLCSegment32 *nonretained_segment;
    
    struct section section;
}

// Just to resolve multiple different definitions...
- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor segment:(CDLCSegment32 *)aSegment;
{
    if ((self = [super init])) {
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
        char buf[17];
        NSString *str;
        
        memcpy(buf, section.segname, 16);
        buf[16] = 0;
        str = [[NSString alloc] initWithBytes:buf length:strlen(buf) encoding:NSASCIIStringEncoding];
        [self setSegmentName:str];
        
        memcpy(buf, section.sectname, 16);
        buf[16] = 0;
        str = [[NSString alloc] initWithBytes:buf length:strlen(buf) encoding:NSASCIIStringEncoding];
        [self setSectionName:str];
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"addr: 0x%08x, offset: %8d, size: %8d [0x%8x], segment; '%@', section: '%@'",
            section.addr, section.offset, section.size, section.size, self.segmentName, self.sectionName];
}

#pragma mark -

@synthesize segment = nonretained_segment;

- (CDMachOFile *)machOFile;
{
    return [self.segment machOFile];
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
    if (self.hasLoadedData == NO) {
        self.data = [[NSData alloc] initWithBytes:[[[nonretained_segment machOFile] machOData] bytes] + section.offset length:section.size];
        self.hasLoadedData = YES;
    }
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
