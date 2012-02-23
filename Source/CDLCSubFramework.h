// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDLoadCommand.h"

@interface CDLCSubFramework : CDLoadCommand
{
    struct sub_framework_command command;
    NSString *name;
}

@property (readonly) NSString *name;

@end
