//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2009 Steve Nygard.  All rights reserved.

#import "CDUnknownLoadCommand.h"

#import "CDDataCursor.h"

@implementation CDUnknownLoadCommand

- (id)initWithDataCursor:(CDDataCursor *)cursor machOFile:(CDMachOFile *)aMachOFile;
{
    if ([super initWithDataCursor:cursor machOFile:aMachOFile] == nil)
        return nil;

    loadCommand.cmd = [cursor readInt32];
    loadCommand.cmdsize = [cursor readInt32];

    if (loadCommand.cmdsize > 8) {
        commandData = [[NSMutableData alloc] init];
        [cursor appendBytesOfLength:loadCommand.cmdsize - 8 intoData:commandData];
    } else {
        commandData = nil;
    }

    return self;
}

- (void)dealloc;
{
    [commandData release];

    [super dealloc];
}

- (uint32_t)cmd;
{
    return loadCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return loadCommand.cmdsize;
}

@end
