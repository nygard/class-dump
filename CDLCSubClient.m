// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDLCSubClient.h"

#import "CDDataCursor.h"

@implementation CDLCSubClient

- (id)initWithDataCursor:(CDDataCursor *)cursor machOFile:(CDMachOFile *)aMachOFile;
{
    NSUInteger length;
    uint32_t strOffset;

    if ([super initWithDataCursor:cursor machOFile:aMachOFile] == nil)
        return nil;

    command.cmd = [cursor readInt32];
    command.cmdsize = [cursor readInt32];

    strOffset = [cursor readInt32];
    NSAssert(strOffset == 12, @"expected strOffset to be 8");

    length = command.cmdsize - sizeof(command);
    //NSLog(@"expected length: %u", length);

    name = [[cursor readStringOfLength:length encoding:NSASCIIStringEncoding] retain];
    //NSLog(@"name: %@", name);

    return self;
}

- (void)dealloc;
{
    [name release];

    [super dealloc];
}

- (uint32_t)cmd;
{
    return command.cmd;
}

- (uint32_t)cmdsize;
{
    return command.cmdsize;
}

- (NSString *)name;
{
    return name;
}

@end
