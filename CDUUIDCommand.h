// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2007 Steve Nygard.  All rights reserved.

#import "CDLoadCommand.h"

#import <CoreFoundation/CoreFoundation.h>

@interface CDUUIDCommand : CDLoadCommand
{
    CFUUIDRef uuid;
}

- (id)initWithPointer:(const void *)ptr machOFile:(CDMachOFile *)aMachOFile;
- (void)dealloc;

- (void)appendToString:(NSMutableString *)resultString;

@end
