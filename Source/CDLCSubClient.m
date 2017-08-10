// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDLCSubClient.h"

@implementation CDLCSubClient
{
    struct sub_client_command _command;
    NSString *_name;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        _command.cmd     = [cursor readInt32];
        _command.cmdsize = [cursor readInt32];
        
        uint32_t strOffset = [cursor readInt32];
        NSParameterAssert(strOffset == 12);
        
        NSUInteger length = _command.cmdsize - sizeof(_command);
        //NSLog(@"expected length: %u", length);
        
        _name = [cursor readStringOfLength:length encoding:NSASCIIStringEncoding];
        //NSLog(@"name: %@", _name);
    }

    return self;
}

#pragma mark -

- (uint32_t)cmd;
{
    return _command.cmd;
}

- (uint32_t)cmdsize;
{
    return _command.cmdsize;
}

@end
