// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2014 Steve Nygard.

#import "CDSection.h"

#include <mach-o/loader.h>
#import "CDMachOFile.h"
#import "CDMachOFileDataCursor.h"
#import "CDLCSegment.h"

@implementation CDSection
{
    struct section_64 _section; // 64-bit, also holding 32-bit
}

@synthesize data = _data;

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor segment:(CDLCSegment *)segment;
{
    if ((self = [super init])) {
        _segment = segment;
        
        [cursor readBytesOfLength:16 intoBuffer:_section.sectname];
        [cursor readBytesOfLength:16 intoBuffer:_section.segname];
        _section.addr      = [cursor readPtr];
        _section.size      = [cursor readPtr];
        _section.offset    = [cursor readInt32];
        _section.align     = [cursor readInt32];
        _section.reloff    = [cursor readInt32];
        _section.nreloc    = [cursor readInt32];
        _section.flags     = [cursor readInt32];
        _section.reserved1 = [cursor readInt32];
        _section.reserved2 = [cursor readInt32];
        if (cursor.machOFile.uses64BitABI) {
            _section.reserved3 = [cursor readInt32];
        }
        
        // These aren't guaranteed to be null terminated.  Witness __cstring_object in __OBJC segment
        char buf[17];
        
        memcpy(buf, _section.segname, 16);
        buf[16] = 0;
        _segmentName = [[NSString alloc] initWithBytes:buf length:strlen(buf) encoding:NSASCIIStringEncoding];
        
        memcpy(buf, _section.sectname, 16);
        buf[16] = 0;
        _sectionName = [[NSString alloc] initWithBytes:buf length:strlen(buf) encoding:NSASCIIStringEncoding];
    }

    return self;
}

#pragma mark -

- (NSData *)data;
{
    if (!_data) {
        _data = [[NSData alloc] initWithBytes:(uint8_t *)[self.segment.machOFile.data bytes] + _section.offset length:_section.size];
    }
    return _data;
}

- (NSUInteger)addr;
{
    return _section.addr;
}

- (NSUInteger)size;
{
    return _section.size;
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

#pragma mark - Debugging

- (NSString *)description;
{
    int padding = (int)self.segment.machOFile.ptrSize * 2;
    return [NSString stringWithFormat:@"<%@:%p> '%@,%-16s' addr: %0*llx, size: %0*llx",
            NSStringFromClass([self class]), self,
            self.segmentName, [self.sectionName UTF8String],
            padding, _section.addr, padding, _section.size];
}

@end
