//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2007  Steve Nygard

#import "CDPathUnitTest.h"

#import <Foundation/Foundation.h>

@implementation CDPathUnitTest

- (void)testPrivateSyncFramework;
{
    NSString *path = @"/System/Library/PrivateFrameworks/SyndicationUI.framework";
    NSBundle *bundle;

    bundle = [NSBundle bundleWithPath:path];
    STAssertNotNil(bundle, @"%@ doesn't seem to exist, we can remove this test now.", path);
    if (bundle != nil) {
        STAssertNil([bundle executablePath], @"This fails on 10.5.  It's fixed if you see this!  Executable path for %@", path);
        //STAssertNotNil([bundle executablePath], @"This fails on 10.5.  Executable path for %@", path);
    }
}

@end
