// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDLoadCommand.h"

#import <CoreFoundation/CoreFoundation.h>

@interface CDLCUUID : CDLoadCommand
{
    struct uuid_command uuidCommand;

    CFUUIDRef uuid;
}

@property (readonly) NSString *uuidString;

@end
