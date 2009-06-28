//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2009 Steve Nygard.  All rights reserved.

#import "CDLCDylinker.h"

#import "CDDataCursor.h"

@implementation CDLCDylinker

- (id)initWithDataCursor:(CDDataCursor *)cursor machOFile:(CDMachOFile *)aMachOFile;
{
    NSUInteger commandOffset;
    NSUInteger length;

    if ([super initWithDataCursor:cursor machOFile:aMachOFile] == nil)
        return nil;

    commandOffset = [cursor offset];
    dylinkerCommand.cmd = [cursor readInt32];
    dylinkerCommand.cmdsize = [cursor readInt32];

    dylinkerCommand.name.offset = [cursor readInt32];

    //NSLog(@"commandOffset: 0x%08x", commandOffset);
    //NSLog(@"dylinkerCommand.dylib.name.offset: 0x%08x", dylinkerCommand.dylib.name.offset);
    //NSLog(@"offset after fixed dylib struct: %08x", [cursor offset]);
    //NSLog(@"off1 + off2: 0x%08x", commandOffset + dylinkerCommand.dylib.name.offset);

    length = dylinkerCommand.cmdsize - sizeof(dylinkerCommand);
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
    return dylinkerCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return dylinkerCommand.cmdsize;
}

- (NSString *)name;
{
    return name;
}

@end
