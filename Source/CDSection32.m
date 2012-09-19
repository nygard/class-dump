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
    
    struct section _section;
}

// Just to resolve multiple different definitions...
- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor segment:(CDLCSegment32 *)segment;
{
    if ((self = [super init])) {
        nonretained_segment = segment;
        
        [cursor readBytesOfLength:16 intoBuffer:_section.sectname];
        [cursor readBytesOfLength:16 intoBuffer:_section.segname];
        _section.addr      = [cursor readInt32];
        _section.size      = [cursor readInt32];
        _section.offset    = [cursor readInt32];
        _section.align     = [cursor readInt32];
        _section.reloff    = [cursor readInt32];
        _section.nreloc    = [cursor readInt32];
        _section.flags     = [cursor readInt32];
        _section.reserved1 = [cursor readInt32];
        _section.reserved2 = [cursor readInt32];
        
        // These aren't guaranteed to be null terminated.  Witness __cstring_object in __OBJC segment
        char buf[17];
        
        memcpy(buf, _section.segname, 16);
        buf[16] = 0;
        self.segmentName = [[NSString alloc] initWithBytes:buf length:strlen(buf) encoding:NSASCIIStringEncoding];
        
        memcpy(buf, _section.sectname, 16);
        buf[16] = 0;
        self.sectionName = [[NSString alloc] initWithBytes:buf length:strlen(buf) encoding:NSASCIIStringEncoding];
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"addr: 0x%08x, offset: %8d, size: %8d [0x%8x], segment; '%@', section: '%@'",
            _section.addr, _section.offset, _section.size, _section.size, self.segmentName, self.sectionName];
}

#pragma mark -

@synthesize segment = nonretained_segment;

- (CDMachOFile *)machOFile;
{
    return [self.segment machOFile];
}

- (NSUInteger)addr;
{
    return _section.addr;
}

- (NSUInteger)size;
{
    return _section.size;
}

- (uint32_t)offset;
{
    return _section.offset;
}

- (void)loadData;
{
    if (self.hasLoadedData == NO) {
        self.data = [[NSData alloc] initWithBytes:(uint8_t *)[self.segment.machOFile.data bytes] + _section.offset length:_section.size];
        self.hasLoadedData = YES;
    }
}

- (BOOL)containsAddress:(NSUInteger)address;
{
    return (address >= _section.addr) && (address < _section.addr + _section.size);
}

- (NSUInteger)fileOffsetForAddress:(NSUInteger)address;
{
    NSParameterAssert([self containsAddress:address]);
    return _section.offset + address - _section.addr;
}

@end
