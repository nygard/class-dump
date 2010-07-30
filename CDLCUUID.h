// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDLoadCommand.h"

#import <CoreFoundation/CoreFoundation.h>

@interface CDLCUUID : CDLoadCommand
{
    struct uuid_command uuidCommand;

    CFUUIDRef uuid;
}

- (id)initWithDataCursor:(CDDataCursor *)cursor machOFile:(CDMachOFile *)aMachOFile;
- (void)dealloc;

- (uint32_t)cmd;
- (uint32_t)cmdsize;

- (NSString *)uuidString;

- (void)appendToString:(NSMutableString *)resultString verbose:(BOOL)isVerbose;

@end
