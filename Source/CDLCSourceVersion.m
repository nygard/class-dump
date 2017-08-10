// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDLCSourceVersion.h"

#import "CDMachOFile.h"

@implementation CDLCSourceVersion
{
    struct source_version_command _sourceVersionCommand;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        _sourceVersionCommand.cmd     = [cursor readInt32];
        _sourceVersionCommand.cmdsize = [cursor readInt32];
        _sourceVersionCommand.version = [cursor readInt64];
    }

    return self;
}

#pragma mark -

- (uint32_t)cmd;
{
    return _sourceVersionCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return _sourceVersionCommand.cmdsize;
}

- (NSString *)sourceVersionString;
{
    // A.B.C.D.E packed as a24.b10.c10.d10.e10
    uint32_t a = (_sourceVersionCommand.version >> 40);
    uint32_t b = (_sourceVersionCommand.version >> 30) & 0x3f;
    uint32_t c = (_sourceVersionCommand.version >> 20) & 0x3f;
    uint32_t d = (_sourceVersionCommand.version >> 10) & 0x3f;
    uint32_t e = _sourceVersionCommand.version & 0x3f;

    return [NSString stringWithFormat:@"%u.%u.%u.%u.%u", a, b, c, d, e];
}

- (void)appendToString:(NSMutableString *)resultString verbose:(BOOL)isVerbose;
{
    [super appendToString:resultString verbose:isVerbose];

    [resultString appendFormat:@"    Source version: %@\n", self.sourceVersionString];
}

@end
