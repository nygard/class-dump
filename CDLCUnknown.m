// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDLCUnknown.h"

#import "CDDataCursor.h"

static BOOL debug = NO;

@implementation CDLCUnknown

- (id)initWithDataCursor:(CDDataCursor *)cursor machOFile:(CDMachOFile *)aMachOFile;
{
    if ([super initWithDataCursor:cursor machOFile:aMachOFile] == nil)
        return nil;

    if (debug) NSLog(@"offset: %u", [cursor offset]);
    loadCommand.cmd = [cursor readInt32];
    loadCommand.cmdsize = [cursor readInt32];
    if (debug) NSLog(@"cmdsize: %u", loadCommand.cmdsize);

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
