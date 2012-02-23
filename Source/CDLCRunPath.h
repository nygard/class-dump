// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDLoadCommand.h"

@interface CDLCRunPath : CDLoadCommand
{
    struct rpath_command rpathCommand;
    NSString *path;
}

@property (readonly) NSString *path;
@property (readonly) NSString *resolvedRunPath;

@end
