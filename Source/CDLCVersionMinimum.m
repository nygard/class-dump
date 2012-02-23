// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDLCVersionMinimum.h"

#import "CDMachOFile.h"

@implementation CDLCVersionMinimum
{
    struct version_min_command versionMinCommand;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        versionMinCommand.cmd = [cursor readInt32];
        versionMinCommand.cmdsize = [cursor readInt32];
        versionMinCommand.version = [cursor readInt32];
        versionMinCommand.reserved = [cursor readInt32];
    }

    return self;
}

#pragma mark -

- (uint32_t)cmd;
{
    return versionMinCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return versionMinCommand.cmdsize;
}

- (NSString *)minimumVersionString;
{
    uint32_t x = (versionMinCommand.version >> 16);
    uint32_t y = (versionMinCommand.version >> 8) & 0xff;
    uint32_t z = versionMinCommand.version & 0xff;

    return [NSString stringWithFormat:@"%u.%u.%u", x, y, z];
}

- (void)appendToString:(NSMutableString *)resultString verbose:(BOOL)isVerbose;
{
    [super appendToString:resultString verbose:isVerbose];

    [resultString appendFormat:@"    Minimum version: %@\n", self.minimumVersionString];
}

@end
