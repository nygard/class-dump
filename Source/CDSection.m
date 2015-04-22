// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

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
        
        _sectionName = [cursor readStringOfLength:16 encoding:NSASCIIStringEncoding];
        memcpy(_section.sectname, [_sectionName UTF8String], sizeof(_section.sectname));
        _segmentName = [cursor readStringOfLength:16 encoding:NSASCIIStringEncoding];
        memcpy(_section.segname, [_segmentName UTF8String], sizeof(_section.segname));
        _section.addr      = [cursor readPtr];
        _section.size      = [cursor readPtr];
        _section.offset    = [cursor readInt32];
        uint32_t dyldOffset = (uint32_t)(_section.addr - segment.vmaddr + segment.fileoff);
        if (_section.offset > 0 && _section.offset != dyldOffset) {
            fprintf(stderr, "Warning: Invalid section offset 0x%08x replaced with 0x%08x in %s,%s\n", _section.offset, dyldOffset, [_segmentName UTF8String], [_sectionName UTF8String]);
            _section.offset = dyldOffset;
        }
        _section.align     = [cursor readInt32];
        _section.reloff    = [cursor readInt32];
        _section.nreloc    = [cursor readInt32];
        _section.flags     = [cursor readInt32];
        _section.reserved1 = [cursor readInt32];
        _section.reserved2 = [cursor readInt32];
        if (cursor.machOFile.uses64BitABI) {
            _section.reserved3 = [cursor readInt32];
        }
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
