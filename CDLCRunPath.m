// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import "CDLCRunPath.h"

#import "CDDataCursor.h"

@implementation CDLCRunPath

- (id)initWithDataCursor:(CDDataCursor *)cursor machOFile:(CDMachOFile *)aMachOFile;
{
    NSUInteger length;

    if ([super initWithDataCursor:cursor machOFile:aMachOFile] == nil)
        return nil;

    rpathCommand.cmd = [cursor readInt32];
    rpathCommand.cmdsize = [cursor readInt32];

    rpathCommand.path.offset = [cursor readInt32];

    length = rpathCommand.cmdsize - sizeof(rpathCommand);
    //NSLog(@"expected length: %u", length);

    path = [[cursor readStringOfLength:length encoding:NSASCIIStringEncoding] retain];
    NSLog(@"path: %@", path);

    return self;
}

- (void)dealloc;
{
    [path release];

    [super dealloc];
}

- (uint32_t)cmd;
{
    return rpathCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return rpathCommand.cmdsize;
}

- (NSString *)path;
{
    return path;
}

@end
