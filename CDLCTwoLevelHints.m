// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDLCTwoLevelHints.h"

#import "CDFatFile.h"
#import "CDMachOFile.h"

@implementation CDLCTwoLevelHints

- (id)initWithDataCursor:(CDDataCursor *)cursor machOFile:(CDMachOFile *)aMachOFile;
{
    if ([super initWithDataCursor:cursor machOFile:aMachOFile] == nil)
        return nil;

    hintsCommand.cmd = [cursor readInt32];
    hintsCommand.cmdsize = [cursor readInt32];
    hintsCommand.offset = [cursor readInt32];
    hintsCommand.nhints = [cursor readInt32];

    return self;
}

- (uint32_t)cmd;
{
    return hintsCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return hintsCommand.cmdsize;
}

@end
