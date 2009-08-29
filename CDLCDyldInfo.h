// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import "CDLoadCommand.h"

@interface CDLCDyldInfo : CDLoadCommand
{
    struct dyld_info_command dyldInfoCommand;
}

- (id)initWithDataCursor:(CDDataCursor *)cursor machOFile:(CDMachOFile *)aMachOFile;

- (uint32_t)cmd;
- (uint32_t)cmdsize;

- (void)logRebaseInfo;

- (void)rebaseAddress:(uint64_t)address type:(uint8_t)type;

@end
