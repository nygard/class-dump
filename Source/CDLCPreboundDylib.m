// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDLCPreboundDylib.h"

#import "CDFatFile.h"
#import "CDMachOFile.h"

@implementation CDLCPreboundDylib
{
    struct prebound_dylib_command _preboundDylibCommand;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        //NSLog(@"current offset: %u", [cursor offset]);
        _preboundDylibCommand.cmd     = [cursor readInt32];
        _preboundDylibCommand.cmdsize = [cursor readInt32];
        //NSLog(@"cmdsize: %u", preboundDylibCommand.cmdsize);
        
        _preboundDylibCommand.name.offset           = [cursor readInt32];
        _preboundDylibCommand.nmodules              = [cursor readInt32];
        _preboundDylibCommand.linked_modules.offset = [cursor readInt32];
        
        if (_preboundDylibCommand.cmdsize > 20) {
            // Don't need this info right now.
            [cursor advanceByLength:_preboundDylibCommand.cmdsize - 20];
        }
    }

    return self;
}

#pragma mark -

- (uint32_t)cmd;
{
    return _preboundDylibCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return _preboundDylibCommand.cmdsize;
}

@end
