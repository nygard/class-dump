// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDLCLinkeditData.h"

@implementation CDLCLinkeditData
{
    struct linkedit_data_command linkeditDataCommand;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        linkeditDataCommand.cmd = [cursor readInt32];
        linkeditDataCommand.cmdsize = [cursor readInt32];
        
        linkeditDataCommand.dataoff = [cursor readInt32];
        linkeditDataCommand.datasize = [cursor readInt32];
    }

    return self;
}

#pragma mark -

- (uint32_t)cmd;
{
    return linkeditDataCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return linkeditDataCommand.cmdsize;
}

@end
