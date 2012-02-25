// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDLCPrebindChecksum.h"

@implementation CDLCPrebindChecksum
{
    struct prebind_cksum_command prebindChecksumCommand;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        prebindChecksumCommand.cmd = [cursor readInt32];
        prebindChecksumCommand.cmdsize = [cursor readInt32];
        prebindChecksumCommand.cksum = [cursor readInt32];
    }

    return self;
}

#pragma mark -

- (uint32_t)cmd;
{
    return prebindChecksumCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return prebindChecksumCommand.cmdsize;
}

- (uint32_t)cksum;
{
    return prebindChecksumCommand.cksum;
}

@end
