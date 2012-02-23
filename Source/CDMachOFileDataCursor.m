// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDMachOFileDataCursor.h"

#import "CDMachOFile.h"
#import "CDSection.h"

@implementation CDMachOFileDataCursor
{
    CDMachOFile *nonretained_machOFile;
}

- (id)initWithFile:(CDMachOFile *)aMachOFile;
{
    return [self initWithFile:aMachOFile offset:0];
}

- (id)initWithFile:(CDMachOFile *)aMachOFile offset:(NSUInteger)anOffset;
{
    if ((self = [super initWithData:[aMachOFile machOData]])) {
        nonretained_machOFile = aMachOFile;
        [self setOffset:anOffset];
    }

    return self;
}
- (id)initWithFile:(CDMachOFile *)aMachOFile address:(NSUInteger)anAddress;
{
    if ((self = [super initWithData:[aMachOFile machOData]])) {
        nonretained_machOFile = aMachOFile;
        [self setAddress:anAddress];
    }

    return self;
}

- (id)initWithSection:(CDSection *)section;
{
    if ((self = [super initWithData:[section data]])) {
        nonretained_machOFile = [section machOFile];
    }

    return self;
}

#pragma mark -

- (CDMachOFile *)machOFile;
{
    return nonretained_machOFile;
}

- (void)setAddress:(NSUInteger)address;
{
    NSUInteger dataOffset = [nonretained_machOFile dataOffsetForAddress:address];
    [self setOffset:dataOffset];
}

#pragma mark - Read using the current byteOrder

- (uint16_t)readInt16;
{
    if (nonretained_machOFile.byteOrder == CDByteOrder_LittleEndian)
        return [self readLittleInt16];

    return [self readBigInt16];
}

- (uint32_t)readInt32;
{
    if (nonretained_machOFile.byteOrder == CDByteOrder_LittleEndian)
        return [self readLittleInt32];

    return [self readBigInt32];
}

- (uint64_t)readInt64;
{
    if (nonretained_machOFile.byteOrder == CDByteOrder_LittleEndian)
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
    switch ([nonretained_machOFile ptrSize]) {
        case sizeof(uint32_t): return [self readInt32];
        case sizeof(uint64_t): return [self readInt64];
    }
    [NSException raise:NSInternalInconsistencyException format:@"The ptrSize must be either 4 (32-bit) or 8 (64-bit)"];
    return 0;
}

@end
