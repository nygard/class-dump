//  This file is part of __APPNAME__, __SHORT_DESCRIPTION__.
//  Copyright (C) 2008 __OWNER__.  All rights reserved.

#import "CDDataCursor.h"

@implementation CDDataCursor

- (id)initWithData:(NSData *)someData;
{
    if ([super init] == nil)
        return nil;

    data = [someData retain];
    offset = 0;

    return self;
}

- (void)dealloc;
{
    [data release];

    [super dealloc];
}

- (NSData *)data;
{
    return data;
}

- (const void *)bytes;
{
    return [data bytes];
}

- (NSUInteger)offset;
{
    return offset;
}

// Return NO on failure.
- (BOOL)seekToPosition:(NSUInteger)newOffset;
{
    if (newOffset <= [data length]) {
        offset = newOffset;
        return YES;
    }

    NSLog(@"Trying to seek past end.");
    return NO;
}

// Return NO on failure.
- (BOOL)readLittleInt16:(uint16_t *)value;
{
    if (offset + sizeof(uint16_t) <= [data length]) {
        if (value != NULL)
            *value = OSReadLittleInt16([data bytes], offset);
        offset += sizeof(uint16_t);
    } else {
        NSLog(@"%s, Trying to read past end.", _cmd);
        return NO;
    }

    return YES;
}

// Return NO on failure.
- (BOOL)readLittleInt32:(uint32_t *)value;
{
    if (offset + sizeof(uint32_t) <= [data length]) {
        if (value != NULL)
            *value = OSReadLittleInt32([data bytes], offset);
        offset += sizeof(uint32_t);
    } else {
        NSLog(@"%s, Trying to read past end.", _cmd);
        return NO;
    }

    return YES;
}

// Return NO on failure.
- (BOOL)readBigInt16:(uint16_t *)value;
{
    if (offset + sizeof(uint16_t) <= [data length]) {
        if (value != NULL)
            *value = OSReadBigInt16([data bytes], offset);
        offset += sizeof(uint16_t);
    } else {
        NSLog(@"%s, Trying to read past end.", _cmd);
        return NO;
    }

    return YES;
}

// Return NO on failure.
- (BOOL)readBigInt32:(uint32_t *)value;
{
    if (offset + sizeof(uint32_t) <= [data length]) {
        if (value != NULL)
            *value = OSReadBigInt32([data bytes], offset);
        offset += sizeof(uint32_t);
    } else {
        NSLog(@"%s, Trying to read past end.", _cmd);
        return NO;
    }

    return YES;
}

// Return NO on failure.
- (BOOL)appendBytesOfLength:(NSUInteger)length intoData:(NSMutableData *)targetData;
{
    if (offset + length <= [data length]) {
        [targetData appendBytes:([self bytes] + offset) length:length];
        offset += length;
    } else {
        NSLog(@"%s, Trying to read past end.", _cmd);
        return NO;
    }

    return YES;
}

// Return nil on failure.
- (NSData *)readDataWithLength:(NSUInteger)length;
{
    NSData *result = nil;

    if (offset + length <= [data length]) {
        // No copy didn't work... alignment problems.  Let's not worry about efficiency for now.
        result = [NSData dataWithBytes:([self bytes] + offset) length:length];
        offset += length;
    } else {
        NSLog(@"%s, Trying to read past end.", _cmd);
    }

    return result;
}

@end
