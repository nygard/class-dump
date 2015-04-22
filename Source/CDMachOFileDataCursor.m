// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDMachOFileDataCursor.h"

#import "CDMachOFile.h"
#import "CDLCSegment.h"
#import "CDSection.h"

@implementation CDMachOFileDataCursor
{
    __weak CDMachOFile *_machOFile;
    NSUInteger _ptrSize;
    CDByteOrder _byteOrder;
}

- (id)initWithFile:(CDMachOFile *)machOFile;
{
    return [self initWithFile:machOFile offset:0];
}

- (id)initWithFile:(CDMachOFile *)machOFile offset:(NSUInteger)offset;
{
    if ((self = [super initWithData:machOFile.data])) {
        self.machOFile = machOFile;
        [self setOffset:offset];
    }

    return self;
}

- (id)initWithFile:(CDMachOFile *)machOFile address:(NSUInteger)address;
{
    if ((self = [super initWithData:machOFile.data])) {
        self.machOFile = machOFile;
        [self setAddress:address];
    }

    return self;
}

- (id)initWithSection:(CDSection *)section;
{
    if ((self = [super initWithData:[section data]])) {
        self.machOFile = section.segment.machOFile;
    }

    return self;
}

#pragma mark -

- (void)setMachOFile:(CDMachOFile *)machOFile;
{
    _machOFile = machOFile;
    _ptrSize = machOFile.ptrSize;
    _byteOrder = machOFile.byteOrder;
}

- (void)setAddress:(NSUInteger)address;
{
    NSUInteger dataOffset = [_machOFile dataOffsetForAddress:address];
    [self setOffset:dataOffset];
}

#pragma mark - Read using the current byteOrder

- (uint16_t)readInt16;
{
    if (_byteOrder == CDByteOrder_LittleEndian)
        return [self readLittleInt16];

    return [self readBigInt16];
}

- (uint32_t)readInt32;
{
    if (_byteOrder == CDByteOrder_LittleEndian)
        return [self readLittleInt32];

    return [self readBigInt32];
}

- (uint64_t)readInt64;
{
    if (_byteOrder == CDByteOrder_LittleEndian)
        return [self readLittleInt64];

    return [self readBigInt64];
}

- (uint32_t)peekInt32;
{
    NSUInteger savedOffset = self.offset;
    uint32_t val = [self readInt32];
    self.offset = savedOffset;
    
    return val;
}

- (uint64_t)readPtr;
{
    switch (_ptrSize) {
        case sizeof(uint32_t): return [self readInt32];
        case sizeof(uint64_t): return [self readInt64];
    }
    [NSException raise:NSInternalInconsistencyException format:@"The ptrSize must be either 4 (32-bit) or 8 (64-bit)"];
    return 0;
}

@end
