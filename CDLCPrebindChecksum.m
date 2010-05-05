// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDLCPrebindChecksum.h"

#import "CDDataCursor.h"

@implementation CDLCPrebindChecksum

- (id)initWithDataCursor:(CDDataCursor *)cursor machOFile:(CDMachOFile *)aMachOFile;
{
    if ([super initWithDataCursor:cursor machOFile:aMachOFile] == nil)
        return nil;

    prebindChecksumCommand.cmd = [cursor readInt32];
    prebindChecksumCommand.cmdsize = [cursor readInt32];
    prebindChecksumCommand.cksum = [cursor readInt32];

    return self;
}

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
