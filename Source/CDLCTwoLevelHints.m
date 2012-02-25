// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDLCTwoLevelHints.h"

#import "CDMachOFile.h"

@implementation CDLCTwoLevelHints
{
    struct twolevel_hints_command hintsCommand;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        hintsCommand.cmd = [cursor readInt32];
        hintsCommand.cmdsize = [cursor readInt32];
        hintsCommand.offset = [cursor readInt32];
        hintsCommand.nhints = [cursor readInt32];
    }

    return self;
}

#pragma mark -

- (uint32_t)cmd;
{
    return hintsCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return hintsCommand.cmdsize;
}

@end
