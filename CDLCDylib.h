// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDLoadCommand.h"
#include <mach-o/loader.h>

@interface CDLCDylib : CDLoadCommand
{
    struct dylib_command dylibCommand;
    NSString *path;
}

- (id)initWithDataCursor:(CDDataCursor *)cursor machOFile:(CDMachOFile *)aMachOFile;
- (void)dealloc;

- (uint32_t)cmd;
- (uint32_t)cmdsize;

- (NSString *)path;
- (uint32_t)timestamp;
- (uint32_t)currentVersion;
- (uint32_t)compatibilityVersion;

- (NSString *)formattedCurrentVersion;
- (NSString *)formattedCompatibilityVersion;

//- (NSString *)extraDescription;

@end
