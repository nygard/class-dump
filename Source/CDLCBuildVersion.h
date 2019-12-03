// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

// M_20191104 BlackDady support Framework Catalina 10.15.1 XCode 11.2b2

#import "CDLoadCommand.h"

// M_20191104
#if (!defined(PLATFORM_IOSMAC))
#define PLATFORM_IOSMAC 6
#endif

#if (!defined(PLATFORM_MACCATALYST))
#define PLATFORM_MACCATALYST 6
#endif

#if (!defined(PLATFORM_DRIVERKIT))
#define PLATFORM_DRIVERKIT 10
#endif
// END M_20191104



@interface CDLCBuildVersion : CDLoadCommand

@property (nonatomic, readonly) NSString *buildVersionString;
@property (nonatomic, readonly) NSArray *toolStrings;
@end
