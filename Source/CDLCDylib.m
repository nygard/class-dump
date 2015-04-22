// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDLCDylib.h"

#import "CDFatFile.h"
#import "CDMachOFile.h"

static NSString *CDDylibVersionString(uint32_t version)
{
    return [NSString stringWithFormat:@"%d.%d.%d", version >> 16, (version >> 8) & 0xff, version & 0xff];
}

@implementation CDLCDylib
{
    struct dylib_command _dylibCommand;
    NSString *_path;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        _dylibCommand.cmd     = [cursor readInt32];
        _dylibCommand.cmdsize = [cursor readInt32];
        
        _dylibCommand.dylib.name.offset           = [cursor readInt32];
        _dylibCommand.dylib.timestamp             = [cursor readInt32];
        _dylibCommand.dylib.current_version       = [cursor readInt32];
        _dylibCommand.dylib.compatibility_version = [cursor readInt32];
        
        NSUInteger length = _dylibCommand.cmdsize - sizeof(_dylibCommand);
        //NSLog(@"expected length: %u", length);
        
        _path = [cursor readStringOfLength:length encoding:NSASCIIStringEncoding];
        //NSLog(@"path: %@", path);
    }

    return self;
}

#pragma mark -

- (uint32_t)cmd;
{
    return _dylibCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return _dylibCommand.cmdsize;
}

- (uint32_t)timestamp;
{
    return _dylibCommand.dylib.timestamp;
}

- (uint32_t)currentVersion;
{
    return _dylibCommand.dylib.current_version;
}

- (uint32_t)compatibilityVersion;
{
    return _dylibCommand.dylib.compatibility_version;
}

- (NSString *)formattedCurrentVersion;
{
    return CDDylibVersionString(self.currentVersion);
}

- (NSString *)formattedCompatibilityVersion;
{
    return CDDylibVersionString(self.compatibilityVersion);
}

#if 0
- (NSString *)extraDescription;
{
    return [NSString stringWithFormat:@"%@ (compatibility version %@, current version %@, timestamp %d [%@])",
                     self.path, CDDylibVersionString(self.compatibilityVersion), CDDylibVersionString(self.currentVersion),
                     self.timestamp, [NSDate dateWithTimeIntervalSince1970:self.timestamp]];
}
#endif

@end
