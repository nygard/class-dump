// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDLoadCommand.h"

@interface CDLCDylib : CDLoadCommand
{
    struct dylib_command dylibCommand;
    NSString *path;
}

@property (readonly) NSString *path;
@property (readonly) uint32_t timestamp;
@property (readonly) uint32_t currentVersion;
@property (readonly) uint32_t compatibilityVersion;

@property (readonly) NSString *formattedCurrentVersion;
@property (readonly) NSString *formattedCompatibilityVersion;

@end
