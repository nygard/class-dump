// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDLCRunPath.h"

#import "CDMachOFile.h"
#import "CDSearchPathState.h"

@implementation CDLCRunPath
{
    struct rpath_command _rpathCommand;
    NSString *_path;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        _rpathCommand.cmd     = [cursor readInt32];
        _rpathCommand.cmdsize = [cursor readInt32];
        
        _rpathCommand.path.offset = [cursor readInt32];
        
        NSUInteger length = _rpathCommand.cmdsize - sizeof(_rpathCommand);
        //NSLog(@"expected length: %u", length);
        
        _path = [cursor readStringOfLength:length encoding:NSASCIIStringEncoding];
        //NSLog(@"path: %@", _path);
    }

    return self;
}

#pragma mark -

- (uint32_t)cmd;
{
    return _rpathCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return _rpathCommand.cmdsize;
}

- (NSString *)resolvedRunPath;
{
    NSString *loaderPathPrefix = @"@loader_path";
    NSString *executablePathPrefix = @"@executable_path";

    if ([self.path hasPrefix:loaderPathPrefix]) {
        NSString *loaderPath = [self.machOFile.filename stringByDeletingLastPathComponent];
        NSString *str = [[self.path stringByReplacingOccurrencesOfString:loaderPathPrefix withString:loaderPath] stringByStandardizingPath];

        return str;
    }

    if ([self.path hasPrefix:executablePathPrefix]) {
        NSString *str = @"";
        NSString *executablePath = self.machOFile.searchPathState.executablePath;
        if (executablePath)
            str = [[self.path stringByReplacingOccurrencesOfString:executablePathPrefix withString:executablePath] stringByStandardizingPath];

        return str;
    }

    return self.path;
}

@end
