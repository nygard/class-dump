// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDLCDylinker.h"

@implementation CDLCDylinker
{
    struct dylinker_command dylinkerCommand;
    NSString *name;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        dylinkerCommand.cmd = [cursor readInt32];
        dylinkerCommand.cmdsize = [cursor readInt32];

        dylinkerCommand.name.offset = [cursor readInt32];
        
        NSUInteger length = dylinkerCommand.cmdsize - sizeof(dylinkerCommand);
        //NSLog(@"expected length: %u", length);
        
        name = [cursor readStringOfLength:length encoding:NSASCIIStringEncoding];
        //NSLog(@"name: %@", name);
    }

    return self;
}

#pragma mark -

- (uint32_t)cmd;
{
    return dylinkerCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return dylinkerCommand.cmdsize;
}

@synthesize name;

@end
