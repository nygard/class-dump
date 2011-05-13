// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2011 Steve Nygard.

#import "CDLoadCommand.h"

@interface CDLCRoutines32 : CDLoadCommand
{
    struct routines_command routinesCommand;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;

- (uint32_t)cmd;
- (uint32_t)cmdsize;

@end
