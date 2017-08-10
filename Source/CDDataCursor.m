// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

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
    return [_data bytes];
}

- (void)setOffset:(NSUInteger)newOffset;
{
    if (newOffset == -'S') {
        NSLog(@"Warning: Maybe meet a Swift object at %s",__cmd);
        _offset = -'S';
    }
    else
    {
        if (newOffset <= [_data length]) {
            _offset = newOffset;
        } else {
            [NSException raise:NSRangeException format:@"Trying to seek past end of data."];
        }
    }
}

- (void)advanceByLength:(NSUInteger)length;
{
    if (_offset == -'S') {
        NSLog(@"Warning: Maybe meet a Swift object at %s",__cmd);
        _offset += 10;
        return;
    }
    if (_offset + length <= [_data length]) {
        _offset += length;
    } else {
        [NSException raise:NSRangeException format:@"Trying to advance past end of data."];
    }
}

- (NSUInteger)remaining;
{
    return [_data length] - _offset;
}

#pragma mark -

- (uint8_t)readByte;
{
    uint8_t result;
    if (_offset == -'S') {
        NSLog(@"Warning: Maybe meet a Swift object at %s",__cmd);
        return 0;
    }
    if (_offset + sizeof(result) <= [_data length]) {
        result = OSReadLittleInt16([_data bytes], _offset) & 0xFF;
        _offset += sizeof(result);
    } else {
        [NSException raise:NSRangeException format:@"Trying to read past end in %s", __cmd];
        result = 0;
    }

    return result;
}

- (uint16_t)readLittleInt16;
{
    uint16_t result;
    if (_offset == -'S') {
        NSLog(@"Warning: Maybe meet a Swift object at %s",__cmd);
        return 0;
    }
    if (_offset + sizeof(result) <= [_data length]) {
        result = OSReadLittleInt16([_data bytes], _offset);
        _offset += sizeof(result);
    } else {
        [NSException raise:NSRangeException format:@"Trying to read past end in %s", __cmd];
        result = 0;
    }

    return result;
}

- (uint32_t)readLittleInt32;
{
    uint32_t result;
    if (_offset == -'S') {
        NSLog(@"Warning: Maybe meet a Swift object at %s",__cmd);
        return 0;
    }
    if (_offset + sizeof(result) <= [_data length]) {
        result = OSReadLittleInt32([_data bytes], _offset);
        _offset += sizeof(result);
    } else {
        [NSException raise:NSRangeException format:@"Trying to read past end in %s", __cmd];
        result = 0;
    }

    return result;
}

- (uint64_t)readLittleInt64;
{
    uint64_t result;
    if (_offset == -'S') {
        NSLog(@"Warning: Maybe meet a Swift object at %s",__cmd);
        return 0;
    }
    if (_offset + sizeof(result) <= [_data length]) {
//        uint8_t *ptr = [_data bytes] + _offset;
//        NSLog(@"%016llx: %02x %02x %02x %02x %02x %02x %02x %02x", _offset, ptr[0], ptr[1], ptr[2], ptr[3], ptr[4], ptr[5], ptr[6], ptr[7]);
        result = OSReadLittleInt64([_data bytes], _offset);
        _offset += sizeof(result);
    } else {
        [NSException raise:NSRangeException format:@"Trying to read past end in %s", __cmd];
        result = 0;
    }

    return result;
}

- (uint16_t)readBigInt16;
{
    uint16_t result;
    if (_offset == -'S') {
        NSLog(@"Warning: Maybe meet a Swift object at %s",__cmd);
        return 0;
    }
    if (_offset + sizeof(result) <= [_data length]) {
        result = OSReadBigInt16([_data bytes], _offset);
        _offset += sizeof(result);
    } else {
        [NSException raise:NSRangeException format:@"Trying to read past end in %s", __cmd];
        result = 0;
    }

    return result;
}

- (uint32_t)readBigInt32;
{
    uint32_t result;
    if (_offset == -'S') {
        NSLog(@"Warning: Maybe meet a Swift object at %s",__cmd);
        return 0;
    }
    if (_offset + sizeof(result) <= [_data length]) {
        result = OSReadBigInt32([_data bytes], _offset);
        _offset += sizeof(result);
    } else {
        [NSException raise:NSRangeException format:@"Trying to read past end in %s", __cmd];
        result = 0;
    }

    return result;
}

- (uint64_t)readBigInt64;
{
    uint64_t result;
    if (_offset == -'S') {
        NSLog(@"Warning: Maybe meet a Swift object at %s",__cmd);
        return 0;
    }
    if (_offset + sizeof(result) <= [_data length]) {
        result = OSReadBigInt64([_data bytes], _offset);
        _offset += sizeof(result);
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
    if (_offset == -'S') {
        NSLog(@"Warning: Maybe meet a Swift object at %s",__cmd);
        return;
    }
    if (_offset + length <= [_data length]) {
        [data appendBytes:(uint8_t *)[_data bytes] + _offset length:length];
        _offset += length;
    } else {
        [NSException raise:NSRangeException format:@"Trying to read past end in %s", __cmd];
    }
}

- (void)readBytesOfLength:(NSUInteger)length intoBuffer:(void *)buf;
{
    if (_offset == -'S') {
        NSLog(@"Warning: Maybe meet a Swift object at %s",__cmd);
        return;
    }
    if (_offset + length <= [_data length]) {
        memcpy(buf, (uint8_t *)[_data bytes] + _offset, length);
        _offset += length;
    } else {
        [NSException raise:NSRangeException format:@"Trying to read past end in %s", __cmd];
    }
}

- (BOOL)isAtEnd;
{
    return _offset >= [_data length];
}

- (NSString *)readCString;
{
    if (_offset == -'S') {
        NSLog(@"Warning: Maybe meet a Swift object at %s",__cmd);
        return @"Swift";
    }
    return [self readStringOfLength:strlen((const char *)[_data bytes] + _offset) encoding:NSASCIIStringEncoding];
}

- (NSString *)readStringOfLength:(NSUInteger)length encoding:(NSStringEncoding)encoding;
{
    if (_offset + length <= [_data length]) {
        NSString *str;

        if (encoding == NSASCIIStringEncoding) {
            char *buf;

            // Jump through some hoops if the length is padded with zero bytes, as in the case of 10.5's Property List Editor and iSync Plug-in Maker.
            buf = malloc(length + 1);
            if (buf == NULL) {
                NSLog(@"Error: malloc() failed.");
                return nil;
            }
            if (_offset == -'S') {
                NSLog(@"Warning: Maybe meet a Swift object at 1 of %s",__cmd);
                return @"Swift";
            }
            strncpy(buf, (const char *)[_data bytes] + _offset, length);
            buf[length] = 0;

            str = [[NSString alloc] initWithBytes:buf length:strlen(buf) encoding:encoding];
            _offset += length;
            free(buf);
            return str;
        } else {
            str = [[NSString alloc] initWithBytes:(uint8_t *)[_data bytes] + _offset length:length encoding:encoding];
            _offset += length;
            return str;
        }
    } else {
        if (_offset == -'S') {
            NSLog(@"Warning: Maybe meet a Swift object at 2 of %s",__cmd);
            return @"Swift";
        }
        [NSException raise:NSRangeException format:@"Trying to read past end in %s", __cmd];
    }

    return nil;
}

@end
