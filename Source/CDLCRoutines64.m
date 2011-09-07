// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2011 Steve Nygard.

#import "CDLCRoutines64.h"

@implementation CDLCRoutines64

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        routinesCommand.cmd = [cursor readInt32];
        routinesCommand.cmdsize = [cursor readInt32];
        
        routinesCommand.init_address = [cursor readInt64];
        routinesCommand.init_module = [cursor readInt64];
        routinesCommand.reserved1 = [cursor readInt64];
        routinesCommand.reserved2 = [cursor readInt64];
        routinesCommand.reserved3 = [cursor readInt64];
        routinesCommand.reserved4 = [cursor readInt64];
        routinesCommand.reserved5 = [cursor readInt64];
        routinesCommand.reserved6 = [cursor readInt64];
    }

    return self;
}

#pragma mark -

- (uint32_t)cmd;
{
    return routinesCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return routinesCommand.cmdsize;
}

@end
