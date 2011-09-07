// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2011 Steve Nygard.

#import "CDLCUnknown.h"

static BOOL debug = NO;

@implementation CDLCUnknown

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        if (debug) NSLog(@"offset: %lu", [cursor offset]);
        loadCommand.cmd = [cursor readInt32];
        loadCommand.cmdsize = [cursor readInt32];
        if (debug) NSLog(@"cmdsize: %u", loadCommand.cmdsize);
        
        if (loadCommand.cmdsize > 8) {
            NSMutableData *_commandData = [[NSMutableData alloc] init];
            [cursor appendBytesOfLength:loadCommand.cmdsize - 8 intoData:_commandData];
            commandData = [_commandData copy]; [_commandData release];
        } else {
            commandData = nil;
        }
    }

    return self;
}

- (void)dealloc;
{
    [commandData release];

    [super dealloc];
}

#pragma mark -

- (uint32_t)cmd;
{
    return loadCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return loadCommand.cmdsize;
}

@end
