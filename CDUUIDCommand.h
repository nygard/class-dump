// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2007  Steve Nygard

#import "CDLoadCommand.h"

#import <CoreFoundation/CoreFoundation.h>

@interface CDUUIDCommand : CDLoadCommand
{
    CFUUIDRef uuid;
}

- (id)initWithPointer:(const void *)ptr machOFile:(CDMachOFile *)aMachOFile;
- (void)dealloc;

- (void)appendToString:(NSMutableString *)resultString verbose:(BOOL)isVerbose;

@end
