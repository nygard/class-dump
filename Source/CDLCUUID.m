// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDLCUUID.h"

#import "CDMachOFile.h"

@implementation CDLCUUID
{
    struct uuid_command _uuidCommand;
    
    NSUUID *_UUID;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        _uuidCommand.cmd     = [cursor readInt32];
        _uuidCommand.cmdsize = [cursor readInt32];
        for (NSUInteger index = 0; index < sizeof(_uuidCommand.uuid); index++) {
            _uuidCommand.uuid[index] = [cursor readByte];
        }
        _UUID = [[NSUUID alloc] initWithUUIDBytes:_uuidCommand.uuid];
    }

    return self;
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

- (void)appendToString:(NSMutableString *)resultString verbose:(BOOL)isVerbose;
{
    [super appendToString:resultString verbose:isVerbose];

    [resultString appendString:@"    uuid "];
    [resultString appendString:[self.UUID UUIDString]];
    [resultString appendString:@"\n"];
}

- (NSString *)extraDescription;
{
    return [self.UUID UUIDString];
}

@end
