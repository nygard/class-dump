// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2011 Steve Nygard.

#import "CDLoadCommand.h"

#import <CoreFoundation/CoreFoundation.h>

@interface CDLCVersionMinimum : CDLoadCommand
{
    struct version_min_command versionMinCommand;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;

- (uint32_t)cmd;
- (uint32_t)cmdsize;

@property (readonly) NSString *minimumVersionString;

- (void)appendToString:(NSMutableString *)resultString verbose:(BOOL)isVerbose;

@end
