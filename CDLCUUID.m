// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import "CDLCUUID.h"

#import "CDMachOFile.h"

@implementation CDLCUUID

- (id)initWithDataCursor:(CDDataCursor *)cursor machOFile:(CDMachOFile *)aMachOFile;
{
    unsigned int index;

    if ([super initWithDataCursor:cursor machOFile:aMachOFile] == nil)
        return nil;

    uuidCommand.cmd = [cursor readInt32];
    uuidCommand.cmdsize = [cursor readInt32];
    for (index = 0; index < 16; index++) {
        uuidCommand.uuid[index] = [cursor readByte];
    }
    // Lovely API
    uuid = CFUUIDCreateWithBytes(kCFAllocatorDefault,
                                 uuidCommand.uuid[0],
                                 uuidCommand.uuid[1],
                                 uuidCommand.uuid[2],
                                 uuidCommand.uuid[3],
                                 uuidCommand.uuid[4],
                                 uuidCommand.uuid[5],
                                 uuidCommand.uuid[6],
                                 uuidCommand.uuid[7],
                                 uuidCommand.uuid[8],
                                 uuidCommand.uuid[9],
                                 uuidCommand.uuid[10],
                                 uuidCommand.uuid[11],
                                 uuidCommand.uuid[12],
                                 uuidCommand.uuid[13],
                                 uuidCommand.uuid[14],
                                 uuidCommand.uuid[15]);

    return self;
}

- (void)dealloc;
{
    CFRelease(uuid);

    [super dealloc];
}

- (uint32_t)cmd;
{
    return uuidCommand.cmd;
}

- (uint32_t)cmdsize;
{

    return uuidCommand.cmdsize;
}

- (void)appendToString:(NSMutableString *)resultString verbose:(BOOL)isVerbose;
{
    unsigned int index;
    CFUUIDBytes uuidBytes;
    UInt8 *bytePtr = (UInt8 *)&uuidBytes;
    UInt8 byte;

    [super appendToString:resultString verbose:isVerbose];

    uuidBytes = CFUUIDGetUUIDBytes(uuid);
    [resultString appendString:@"    uuid"];
    for (index = 0; index < 8; index++) {
        byte = bytePtr[index];
        [resultString appendFormat:@" 0x%02x", byte];
    }

    [resultString appendString:@"\n"];
    [resultString appendString:@"        "];
    for (index = 0; index < 8; index++) {
        byte = bytePtr[8 + index];
        [resultString appendFormat:@" 0x%02x", byte];
    }
    [resultString appendString:@"\n"];
}

@end
