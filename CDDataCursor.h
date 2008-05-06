// -*- mode: ObjC -*-

//  This file is part of __APPNAME__, __SHORT_DESCRIPTION__.
//  Copyright (C) 2008 __OWNER__.  All rights reserved.

#import <Foundation/Foundation.h>

@interface CDDataCursor : NSObject
{
    NSData *data;
    NSUInteger offset;
}

- (id)initWithData:(NSData *)someData;
- (void)dealloc;

- (NSData *)data;
- (const void *)bytes;

- (NSUInteger)offset;
- (BOOL)seekToPosition:(NSUInteger)newOffset;

- (BOOL)readLittleInt16:(unsigned short *)value;
- (BOOL)readLittleInt32:(unsigned int *)value;

- (BOOL)readBigInt16:(unsigned short *)value;
- (BOOL)readBigInt32:(unsigned int *)value;

- (BOOL)appendBytesOfLength:(NSUInteger)length intoData:(NSMutableData *)targetData;
- (NSData *)readDataWithLength:(NSUInteger)length;

@end
