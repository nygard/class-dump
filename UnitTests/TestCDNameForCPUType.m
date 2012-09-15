// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "TestCDNameForCPUType.h"

#import "CDFile.h"

@implementation TestCDNameForCPUType

- (void)setUp;
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown;
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testArmv7s;
{
    STAssertEqualObjects(CDNameForCPUType(CPU_TYPE_ARM, 11), @"armv7s", @"The name for ARM subtype 11 should be 'armv7s'");
}

@end
