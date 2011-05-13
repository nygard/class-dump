// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2011 Steve Nygard.

#import "CDDataCursor.h"

@class CDMachOFile, CDLCSegment, CDSection;

@interface CDMachOFileDataCursor : CDDataCursor
{
    CDMachOFile *nonretained_machOFile;
}

- (id)initWithFile:(CDMachOFile *)aMachOFile;
- (id)initWithFile:(CDMachOFile *)aMachOFile offset:(NSUInteger)anOffset;
- (id)initWithFile:(CDMachOFile *)aMachOFile address:(NSUInteger)anAddress;

- (id)initWithSection:(CDSection *)section;

- (CDMachOFile *)machOFile;

- (void)setAddress:(NSUInteger)address;

// Read using the current byteOrder
- (uint16_t)readInt16;
- (uint32_t)readInt32;
- (uint64_t)readInt64;

- (uint32_t)peekInt32;

// Read using the current byteOrder and ptrSize (from the nonretained_machOFile)
- (uint64_t)readPtr;

@end
