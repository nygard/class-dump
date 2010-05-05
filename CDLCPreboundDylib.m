// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDLCPreboundDylib.h"

#import "CDFatFile.h"
#import "CDMachOFile.h"

@implementation CDLCPreboundDylib

- (id)initWithDataCursor:(CDDataCursor *)cursor machOFile:(CDMachOFile *)aMachOFile;
{
    if ([super initWithDataCursor:cursor machOFile:aMachOFile] == nil)
        return nil;

    //NSLog(@"current offset: %u", [cursor offset]);
    preboundDylibCommand.cmd = [cursor readInt32];
    preboundDylibCommand.cmdsize = [cursor readInt32];
    //NSLog(@"cmdsize: %u", preboundDylibCommand.cmdsize);

    preboundDylibCommand.name.offset = [cursor readInt32];
    preboundDylibCommand.nmodules = [cursor readInt32];
    preboundDylibCommand.linked_modules.offset = [cursor readInt32];

    if (preboundDylibCommand.cmdsize > 20) {
        // Don't need this info right now.
        [cursor advanceByLength:preboundDylibCommand.cmdsize - 20];
    }

    //name = [[cursor readCString] retain];
    //NSLog(@"name: %@", name);
    //exit(99);

    return self;
}

- (void)dealloc;
{
    [name release];

    [super dealloc];
}

- (uint32_t)cmd;
{
    return preboundDylibCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return preboundDylibCommand.cmdsize;
}

- (NSString *)name;
{
    return name;
}

@end
