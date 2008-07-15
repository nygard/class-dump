// -*- mode: ObjC -*-

//  This file is part of __APPNAME__, __SHORT_DESCRIPTION__.
//  Copyright (C) 2008 __OWNER__.  All rights reserved.

#import <Foundation/Foundation.h>

@interface CDDataCursor : NSObject
{
    NSData *data;
    NSUInteger offset;
    BOOL isLittleEndian;
}

- (id)initWithData:(NSData *)someData;
- (void)dealloc;

- (NSData *)data;
- (const void *)bytes;

- (NSUInteger)offset;
- (BOOL)seekToPosition:(NSUInteger)newOffset;

- (BOOL)readLittleInt16:(uint16_t *)value;
- (BOOL)readLittleInt32:(uint32_t *)value;

- (BOOL)readBigInt16:(uint16_t *)value;
- (BOOL)readBigInt32:(uint32_t *)value;

- (BOOL)isLittleEndian;
- (void)setIsLittleEndian:(BOOL)newFlag;

- (BOOL)readInt16:(uint16_t *)value;
- (BOOL)readInt32:(uint32_t *)value;

- (BOOL)appendBytesOfLength:(NSUInteger)length intoData:(NSMutableData *)targetData;
- (NSData *)readDataWithLength:(NSUInteger)length;

@end
