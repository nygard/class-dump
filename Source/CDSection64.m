// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDSection64.h"

#include <mach-o/loader.h>
#import "CDMachOFileDataCursor.h"
#import "CDMachOFile.h"
#import "CDLCSegment64.h"

@implementation CDSection64
{
    __weak CDLCSegment64 *nonretained_segment;
    
    struct section_64 _section;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor segment:(CDLCSegment64 *)segment;
{
    if ((self = [super init])) {
        nonretained_segment = segment;
        
        [cursor readBytesOfLength:16 intoBuffer:_section.sectname];
        [cursor readBytesOfLength:16 intoBuffer:_section.segname];
        _section.addr      = [cursor readInt64];
        _section.size      = [cursor readInt64];
        _section.offset    = [cursor readInt32];
        _section.align     = [cursor readInt32];
        _section.reloff    = [cursor readInt32];
        _section.nreloc    = [cursor readInt32];
        _section.flags     = [cursor readInt32];
        _section.reserved1 = [cursor readInt32];
        _section.reserved2 = [cursor readInt32];
        _section.reserved3 = [cursor readInt32];
        
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
    return [NSString stringWithFormat:@"<%@:%p> segment; '%@', section: '%-16s', addr: %016llx, size: %016llx",
            NSStringFromClass([self class]), self,
            self.segmentName, [self.sectionName UTF8String],
            _section.addr, _section.size];
}

#pragma mark -

@synthesize segment = nonretained_segment;

- (CDMachOFile *)machOFile;
{
    return [[self segment] machOFile];
}

- (NSUInteger)addr;
{
    return _section.addr;
}

- (NSUInteger)size;
{
    return _section.size;
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
