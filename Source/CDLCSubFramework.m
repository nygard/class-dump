// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDLCSubFramework.h"

@implementation CDLCSubFramework
{
    struct sub_framework_command command;
    NSString *_name;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        command.cmd     = [cursor readInt32];
        command.cmdsize = [cursor readInt32];
        
        uint32_t strOffset = [cursor readInt32];
        NSParameterAssert(strOffset == 12);
        
        NSUInteger length = command.cmdsize - sizeof(command);
        //NSLog(@"expected length: %u", length);
        
        _name = [cursor readStringOfLength:length encoding:NSASCIIStringEncoding];
        //NSLog(@"name: %@", _name);
    }

    return self;
}

#pragma mark -

- (uint32_t)cmd;
{
    return command.cmd;
}

- (uint32_t)cmdsize;
{
    return command.cmdsize;
}

@end
