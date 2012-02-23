// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDLCRoutines32.h"

@implementation CDLCRoutines32
{
    struct routines_command routinesCommand;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        routinesCommand.cmd = [cursor readInt32];
        routinesCommand.cmdsize = [cursor readInt32];
        
        routinesCommand.init_address = [cursor readInt32];
        routinesCommand.init_module = [cursor readInt32];
        routinesCommand.reserved1 = [cursor readInt32];
        routinesCommand.reserved2 = [cursor readInt32];
        routinesCommand.reserved3 = [cursor readInt32];
        routinesCommand.reserved4 = [cursor readInt32];
        routinesCommand.reserved5 = [cursor readInt32];
        routinesCommand.reserved6 = [cursor readInt32];
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
