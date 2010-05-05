// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import <Foundation/Foundation.h>

enum {
    CDByteOrderLittleEndian = 0,
    CDByteOrderBigEndian = 1,
};
typedef NSUInteger CDByteOrder;

@interface CDDataCursor : NSObject
{
    NSData *data;
    NSUInteger offset;
    CDByteOrder byteOrder;
}

- (id)initWithData:(NSData *)someData;
- (void)dealloc;

- (NSData *)data;
- (const void *)bytes;

- (NSUInteger)offset;
- (void)setOffset:(NSUInteger)newOffset;
- (void)advanceByLength:(NSUInteger)length;
- (NSUInteger)remaining;

- (uint8_t)readByte;

- (uint16_t)readLittleInt16;
- (uint32_t)readLittleInt32;
- (uint64_t)readLittleInt64;

- (uint16_t)readBigInt16;
- (uint32_t)readBigInt32;
- (uint64_t)readBigInt64;

- (float)readLittleFloat32;
- (float)readBigFloat32;

- (double)readLittleFloat64;
//- (double)readBigFloat64;

- (void)appendBytesOfLength:(NSUInteger)length intoData:(NSMutableData *)targetData;
- (void)readBytesOfLength:(NSUInteger)length intoBuffer:(void *)buf;
- (BOOL)isAtEnd;

- (CDByteOrder)byteOrder;
- (void)setByteOrder:(CDByteOrder)newByteOrder;

// Read using the current byteOrder
- (uint16_t)readInt16;
- (uint32_t)readInt32;
- (uint64_t)readInt64;

- (uint32_t)peekInt32;

- (NSString *)readCString;
- (NSString *)readStringOfLength:(NSUInteger)length encoding:(NSStringEncoding)encoding;

@end
