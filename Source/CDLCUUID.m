// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDLCUUID.h"

#import <CoreFoundation/CoreFoundation.h>
#import "CDMachOFile.h"

@implementation CDLCUUID
{
    struct uuid_command _uuidCommand;
    
    CFUUIDRef _uuid;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        _uuidCommand.cmd     = [cursor readInt32];
        _uuidCommand.cmdsize = [cursor readInt32];
        for (NSUInteger index = 0; index < 16; index++) {
            _uuidCommand.uuid[index] = [cursor readByte];
        }
        // Lovely API
        _uuid = CFUUIDCreateWithBytes(kCFAllocatorDefault,
                                     _uuidCommand.uuid[0],
                                     _uuidCommand.uuid[1],
                                     _uuidCommand.uuid[2],
                                     _uuidCommand.uuid[3],
                                     _uuidCommand.uuid[4],
                                     _uuidCommand.uuid[5],
                                     _uuidCommand.uuid[6],
                                     _uuidCommand.uuid[7],
                                     _uuidCommand.uuid[8],
                                     _uuidCommand.uuid[9],
                                     _uuidCommand.uuid[10],
                                     _uuidCommand.uuid[11],
                                     _uuidCommand.uuid[12],
                                     _uuidCommand.uuid[13],
                                     _uuidCommand.uuid[14],
                                     _uuidCommand.uuid[15]);
    }

    return self;
}

- (void)dealloc;
{
    CFRelease(_uuid);
}

#pragma mark -

- (uint32_t)cmd;
{
    return _uuidCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return _uuidCommand.cmdsize;
}

- (NSString *)uuidString;
{
    return (__bridge_transfer NSString *)(CFUUIDCreateString(kCFAllocatorDefault, _uuid));
}

- (void)appendToString:(NSMutableString *)resultString verbose:(BOOL)isVerbose;
{
    [super appendToString:resultString verbose:isVerbose];

    [resultString appendString:@"    uuid "];
    [resultString appendString:[self uuidString]];
    [resultString appendString:@"\n"];
}

@end
