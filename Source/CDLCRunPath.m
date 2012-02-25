// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDLCRunPath.h"

#import "CDMachOFile.h"
#import "CDSearchPathState.h"

@implementation CDLCRunPath
{
    struct rpath_command rpathCommand;
    NSString *path;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        rpathCommand.cmd = [cursor readInt32];
        rpathCommand.cmdsize = [cursor readInt32];
        
        rpathCommand.path.offset = [cursor readInt32];
        
        NSUInteger length = rpathCommand.cmdsize - sizeof(rpathCommand);
        //NSLog(@"expected length: %u", length);
        
        path = [[cursor readStringOfLength:length encoding:NSASCIIStringEncoding] retain];
        //NSLog(@"path: %@", path);
    }

    return self;
}

- (void)dealloc;
{
    [path release];

    [super dealloc];
}

#pragma mark -

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

- (NSString *)resolvedRunPath;
{
    NSString *loaderPathPrefix = @"@loader_path";
    NSString *executablePathPrefix = @"@executable_path";

    if ([path hasPrefix:loaderPathPrefix]) {
        NSString *loaderPath = [self.machOFile.filename stringByDeletingLastPathComponent];
        NSString *str = [[path stringByReplacingOccurrencesOfString:loaderPathPrefix withString:loaderPath] stringByStandardizingPath];

        return str;
    }

    if ([path hasPrefix:executablePathPrefix]) {
        NSString *str = @"";
        NSString *executablePath = self.machOFile.searchPathState.executablePath;
        if (executablePath)
            str = [[path stringByReplacingOccurrencesOfString:executablePathPrefix withString:executablePath] stringByStandardizingPath];

        return str;
    }

    return path;
}

@end
