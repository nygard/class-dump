//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2007  Steve Nygard

#import "CDDylibCommand.h"

#include <mach-o/swap.h>
#import <Foundation/Foundation.h>
#import "CDFatFile.h"
#import "CDMachOFile.h"

// Does this work with different endianness?
static NSString *CDDylibVersionString(unsigned long version)
{
    return [NSString stringWithFormat:@"%d.%d.%d", version >> 16, (version >> 8) & 0xff, version & 0xff];
}

@implementation CDDylibCommand

- (id)initWithDataCursor:(CDDataCursor *)cursor machOFile:(CDMachOFile *)aMachOFile;
{
    NSUInteger commandOffset;
    NSUInteger length;

    if ([super initWithDataCursor:cursor machOFile:aMachOFile] == nil)
        return nil;

    commandOffset = [cursor offset];
    dylibCommand.cmd = [cursor readInt32];
    dylibCommand.cmdsize = [cursor readInt32];

    dylibCommand.dylib.name.offset = [cursor readInt32];
    dylibCommand.dylib.timestamp = [cursor readInt32];
    dylibCommand.dylib.current_version = [cursor readInt32];
    dylibCommand.dylib.compatibility_version = [cursor readInt32];

    //NSLog(@"commandOffset: 0x%08x", commandOffset);
    //NSLog(@"dylibCommand.dylib.name.offset: 0x%08x", dylibCommand.dylib.name.offset);
    //NSLog(@"offset after fixed dylib struct: %08x", [cursor offset]);
    //NSLog(@"off1 + off2: 0x%08x", commandOffset + dylibCommand.dylib.name.offset);

    length = dylibCommand.cmdsize - sizeof(dylibCommand);
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
    return dylibCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return dylibCommand.cmdsize;
}

- (NSString *)name;
{
    return name;
}

- (uint32_t)timestamp;
{
    return dylibCommand.dylib.timestamp;
}

- (uint32_t)currentVersion;
{
    return dylibCommand.dylib.current_version;
}

- (uint32_t)compatibilityVersion;
{
    return dylibCommand.dylib.compatibility_version;
}

- (NSString *)formattedCurrentVersion;
{
    return CDDylibVersionString([self currentVersion]);
}

- (NSString *)formattedCompatibilityVersion;
{
    return CDDylibVersionString([self compatibilityVersion]);
}

#if 0
- (NSString *)extraDescription;
{
    return [NSString stringWithFormat:@"%@ (compatibility version %@, current version %@, timestamp %d [%@])",
                     [self name], CDDylibVersionString([self compatibilityVersion]), CDDylibVersionString([self currentVersion]),
                     [self timestamp], [NSDate dateWithTimeIntervalSince1970:[self timestamp]]];
}
#endif

@end
