//  This file is part of class-dump, a utility for exmaing the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import "CDDylibCommand.h"

#import "rcsid.h"
#import <Foundation/Foundation.h>

RCS_ID("$Header: /Volumes/Data/tmp/Tools/class-dump/CDDylibCommand.m,v 1.3 2004/01/06 02:18:18 nygard Exp $");

// Does this work with different endianness?
static NSString *CDDylibVersionString(unsigned long version)
{
    return [NSString stringWithFormat:@"%d.%d.%d", version >> 16, (version >> 8) & 0xff, version & 0xff];
}

@implementation CDDylibCommand

- (id)initWithPointer:(const void *)ptr machOFile:(CDMachOFile *)aMachOFile;
{
    const char *str;

    if ([super initWithPointer:ptr machOFile:aMachOFile] == nil)
        return nil;

    dylibCommand = ptr;
    str = ptr + dylibCommand->dylib.name.offset;
    name = [[NSString alloc] initWithBytes:str length:strlen(str) encoding:NSASCIIStringEncoding];

    return self;
}

- (void)dealloc;
{
    [name release];
    [super dealloc];
}

- (NSString *)name;
{
    return name;
}

- (unsigned long)timestamp;
{
    return dylibCommand->dylib.timestamp;
}

- (unsigned long)currentVersion;
{
    return dylibCommand->dylib.current_version;
}

- (unsigned long)compatibilityVersion;
{
    return dylibCommand->dylib.compatibility_version;
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
