// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDLCPrebindChecksum.h"

@implementation CDLCPrebindChecksum
{
    struct prebind_cksum_command _prebindChecksumCommand;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        _prebindChecksumCommand.cmd     = [cursor readInt32];
        _prebindChecksumCommand.cmdsize = [cursor readInt32];
        _prebindChecksumCommand.cksum   = [cursor readInt32];
    }

    return self;
}

#pragma mark -

- (uint32_t)cmd;
{
    return _prebindChecksumCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return _prebindChecksumCommand.cmdsize;
}

- (uint32_t)cksum;
{
    return _prebindChecksumCommand.cksum;
}

@end
