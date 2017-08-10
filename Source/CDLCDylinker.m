// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDLCDylinker.h"

@implementation CDLCDylinker
{
    struct dylinker_command _dylinkerCommand;
    NSString *_name;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        _dylinkerCommand.cmd     = [cursor readInt32];
        _dylinkerCommand.cmdsize = [cursor readInt32];

        _dylinkerCommand.name.offset = [cursor readInt32];
        
        NSUInteger length = _dylinkerCommand.cmdsize - sizeof(_dylinkerCommand);
        //NSLog(@"expected length: %u", length);
        
        _name = [cursor readStringOfLength:length encoding:NSASCIIStringEncoding];
        //NSLog(@"name: %@", name);
    }

    return self;
}

#pragma mark -

- (uint32_t)cmd;
{
    return _dylinkerCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return _dylinkerCommand.cmdsize;
}

@end
