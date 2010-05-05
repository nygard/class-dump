// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDLCLinkeditData.h"

#import "CDDataCursor.h"

@implementation CDLCLinkeditData

- (id)initWithDataCursor:(CDDataCursor *)cursor machOFile:(CDMachOFile *)aMachOFile;
{
    if ([super initWithDataCursor:cursor machOFile:aMachOFile] == nil)
        return nil;

    linkeditDataCommand.cmd = [cursor readInt32];
    linkeditDataCommand.cmdsize = [cursor readInt32];

    linkeditDataCommand.dataoff = [cursor readInt32];
    linkeditDataCommand.datasize = [cursor readInt32];

    return self;
}

- (uint32_t)cmd;
{
    return linkeditDataCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return linkeditDataCommand.cmdsize;
}

@end
