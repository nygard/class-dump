// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2011 Steve Nygard.

#import "CDLCMain.h"

@implementation CDLCMain

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        entryPointCommand.cmd = [cursor readInt32];
        entryPointCommand.cmdsize = [cursor readInt32];
        entryPointCommand.entryoff = [cursor readInt64];
        entryPointCommand.stacksize = [cursor readInt64];
    }

    return self;
}

#pragma mark -

- (uint32_t)cmd;
{
    return entryPointCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return entryPointCommand.cmdsize;
}

@end
