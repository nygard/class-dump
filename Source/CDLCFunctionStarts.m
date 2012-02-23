// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDLCFunctionStarts.h"

@implementation CDLCFunctionStarts
{
    struct load_command loadCommand;
    
    NSData *commandData;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        loadCommand.cmd = [cursor readInt32];
        loadCommand.cmdsize = [cursor readInt32];
        
        if (loadCommand.cmdsize > 8) {
            NSMutableData *_commandData = [[NSMutableData alloc] init];
            [cursor appendBytesOfLength:loadCommand.cmdsize - 8 intoData:_commandData];
            commandData = [_commandData copy]; [_commandData release];
        } else {
            commandData = nil;
        }
    }

    return self;
}

- (void)dealloc;
{
    [commandData release];

    [super dealloc];
}

#pragma mark -

- (uint32_t)cmd;
{
    return loadCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return loadCommand.cmdsize;
}

@end
