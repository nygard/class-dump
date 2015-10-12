//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDPathUnitTest.h"

#import <Foundation/Foundation.h>
#import "CDClassDump.h"

@implementation CDPathUnitTest

- (void)setUp;
{
    classDump = [[CDClassDump alloc] init];
}

- (void)tearDown;
{
    [classDump release];
    classDump = nil;
}

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

- (void)testBundlePathWithoutTrailingSlash;
{
    BOOL result;

    result = [classDump processFilename:@"/System/Library/Frameworks/AppKit.framework"];
    STAssertEquals(YES, result, @"Couldn't process AppKit.framework");
    STAssertEqualObjects(@"/System/Library/Frameworks/AppKit.framework/Versions/C", [classDump executablePath], @"");
}

- (void)testBundlePathWithTrailingSlash;
{
    BOOL result;

    result = [classDump processFilename:@"/System/Library/Frameworks/AppKit.framework/"];
    STAssertEquals(YES, result, @"Couldn't process AppKit.framework");
    STAssertEqualObjects(@"/System/Library/Frameworks/AppKit.framework/Versions/C", [classDump executablePath], @"");
}

- (void)testExecutableSymlinkPath;
{
    BOOL result;

    result = [classDump processFilename:@"/System/Library/Frameworks/AppKit.framework/AppKit"];
    STAssertEquals(YES, result, @"Couldn't process AppKit.framework");
    STAssertEqualObjects(@"/System/Library/Frameworks/AppKit.framework/Versions/C", [classDump executablePath], @"");
}

- (void)testExecutableFullPath;
{
    BOOL result;

    result = [classDump processFilename:@"/System/Library/Frameworks/AppKit.framework/Versions/C/AppKit"];
    STAssertEquals(YES, result, @"Couldn't process AppKit.framework");
    STAssertEqualObjects(@"/System/Library/Frameworks/AppKit.framework/Versions/C", [classDump executablePath], @"");
}

@end
