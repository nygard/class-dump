// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDLCUnixThread.h"

// For now, this is all I need.  There is no data in here sensitive to its position in the file.

@implementation CDLCUnixThread
{
    struct load_command _loadCommand;
    
    NSData *_commandData;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        _loadCommand.cmd     = [cursor readInt32];
        _loadCommand.cmdsize = [cursor readInt32];
        
        if (_loadCommand.cmdsize > 8) {
            NSMutableData *commandData = [[NSMutableData alloc] init];
            [cursor appendBytesOfLength:_loadCommand.cmdsize - 8 intoData:commandData];
            _commandData = [commandData copy];
        } else {
            _commandData = nil;
        }
    }

    return self;
}

#pragma mark -

- (uint32_t)cmd;
{
    return _loadCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return _loadCommand.cmdsize;
}

@end
