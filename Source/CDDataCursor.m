// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDDataCursor.h"

@implementation CDDataCursor
{
    NSData *_data;
    NSUInteger _offset;
}

- (id)initWithData:(NSData *)data;
{
    if ((self = [super init])) {
        _data = data;
        _offset = 0;
    }

    return self;
}

#pragma mark -

- (const void *)bytes;
{
    return [self.data bytes];
}

- (void)setOffset:(NSUInteger)newOffset;
{
    if (newOffset <= [self.data length]) {
        _offset = newOffset;
    } else {
        [NSException raise:NSRangeException format:@"Trying to seek past end of data."];
    }
}

- (void)advanceByLength:(NSUInteger)length;
{
    self.offset += length;
}

- (NSUInteger)remaining;
{
    return [self.data length] - self.offset;
}

#pragma mark -

- (uint8_t)readByte;
{
    const uint8_t *ptr;

    ptr = (uint8_t *)[self.data bytes] + self.offset;
    self.offset += 1;

    return *ptr;
}

- (uint16_t)readLittleInt16;
{
    uint16_t result;

    if (self.offset + sizeof(result) <= [self.data length]) {
        result = OSReadLittleInt16([self.data bytes], self.offset);
        self.offset += sizeof(result);
    } else {
        [NSException raise:NSRangeException format:@"Trying to read past end in %s", __cmd];
        result = 0;
    }

    return result;
}

- (uint32_t)readLittleInt32;
{
    uint32_t result;

    if (self.offset + sizeof(result) <= [self.data length]) {
        result = OSReadLittleInt32([self.data bytes], self.offset);
        self.offset += sizeof(result);
    } else {
        [NSException raise:NSRangeException format:@"Trying to read past end in %s", __cmd];
        result = 0;
    }

    return result;
}

- (uint64_t)readLittleInt64;
{
    uint64_t result;

    if (self.offset + sizeof(result) <= [self.data length]) {
        result = OSReadLittleInt64([self.data bytes], self.offset);
        self.offset += sizeof(result);
    } else {
        [NSException raise:NSRangeException format:@"Trying to read past end in %s", __cmd];
        result = 0;
    }

    return result;
}

- (uint16_t)readBigInt16;
{
    uint16_t result;

    if (self.offset + sizeof(result) <= [self.data length]) {
        result = OSReadBigInt16([self.data bytes], self.offset);
        self.offset += sizeof(result);
    } else {
        [NSException raise:NSRangeException format:@"Trying to read past end in %s", __cmd];
        result = 0;
    }

    return result;
}

- (uint32_t)readBigInt32;
{
    uint32_t result;

    if (self.offset + sizeof(result) <= [self.data length]) {
        result = OSReadBigInt32([self.data bytes], self.offset);
        self.offset += sizeof(result);
    } else {
        [NSException raise:NSRangeException format:@"Trying to read past end in %s", __cmd];
        result = 0;
    }

    return result;
}

- (uint64_t)readBigInt64;
{
    uint64_t result;

    if (self.offset + sizeof(result) <= [self.data length]) {
        result = OSReadBigInt64([self.data bytes], self.offset);
        self.offset += sizeof(result);
    } else {
        [NSException raise:NSRangeException format:@"Trying to read past end in %s", __cmd];
        result = 0;
    }

    return result;
}

- (float)readLittleFloat32;
{
    uint32_t val;

    val = [self readLittleInt32];
    return *(float *)&val;
}

- (float)readBigFloat32;
{
    uint32_t val;

    val = [self readBigInt32];
    return *(float *)&val;
}

- (double)readLittleFloat64;
{
    uint32_t v1, v2, *ptr;
    double dval;

    v1 = [self readLittleInt32];
    v2 = [self readLittleInt32];
    ptr = (uint32_t *)&dval;
    *ptr++ = v1;
    *ptr = v2;

    return dval;
}

- (void)appendBytesOfLength:(NSUInteger)length intoData:(NSMutableData *)data;
{
    if (self.offset + length <= [self.data length]) {
        [data appendBytes:(uint8_t *)[self.data bytes] + self.offset length:length];
        self.offset += length;
    } else {
        [NSException raise:NSRangeException format:@"Trying to read past end in %s", __cmd];
    }
}

- (void)readBytesOfLength:(NSUInteger)length intoBuffer:(void *)buf;
{
    if (self.offset + length <= [self.data length]) {
        memcpy(buf, (uint8_t *)[self.data bytes] + self.offset, length);
        self.offset += length;
    } else {
        [NSException raise:NSRangeException format:@"Trying to read past end in %s", __cmd];
    }
}

- (BOOL)isAtEnd;
{
    return self.offset >= [self.data length];
}

- (NSString *)readCString;
{
    return [self readStringOfLength:strlen((const char *)[self.data bytes] + self.offset) encoding:NSASCIIStringEncoding];
}

- (NSString *)readStringOfLength:(NSUInteger)length encoding:(NSStringEncoding)encoding;
{
    if (self.offset + length <= [self.data length]) {
        NSString *str;

        if (encoding == NSASCIIStringEncoding) {
            char *buf;

            // Jump through some hoops if the length is padded with zero bytes, as in the case of 10.5's Property List Editor and iSync Plug-in Maker.
            buf = malloc(length + 1);
            if (buf == NULL) {
                NSLog(@"Error: malloc() failed.");
                return nil;
            }

            strncpy(buf, (const char *)[self.data bytes] + self.offset, length);
            buf[length] = 0;

            str = [[NSString alloc] initWithBytes:buf length:strlen(buf) encoding:encoding];
            self.offset += length;
            free(buf);
            return str;
        } else {
            str = [[NSString alloc] initWithBytes:(uint8_t *)[self.data bytes] + self.offset length:length encoding:encoding];
            self.offset += length;
            return str;
        }
    } else {
        [NSException raise:NSRangeException format:@"Trying to read past end in %s", __cmd];
    }

    return nil;
}

@end
