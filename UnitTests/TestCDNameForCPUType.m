// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import <XCTest/XCTest.h>

#import "CDFile.h"

@interface TestCDNameForCPUType : XCTestCase
@end

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

#pragma mark - ARM

- (void)test_armv6;
{
    XCTAssertEqualObjects(CDNameForCPUType(CPU_TYPE_ARM, CPU_SUBTYPE_ARM_V6), @"armv6", @"The name for ARM subtype CPU_SUBTYPE_ARM_V6 should be 'armv6'");
}

- (void)test_armv7;
{
    XCTAssertEqualObjects(CDNameForCPUType(CPU_TYPE_ARM, CPU_SUBTYPE_ARM_V7), @"armv7", @"The name for ARM subtype CPU_SUBTYPE_ARM_V7 should be 'armv7'");
}

- (void)test_armv7s;
{
    XCTAssertEqualObjects(CDNameForCPUType(CPU_TYPE_ARM, 11), @"armv7s", @"The name for ARM subtype 11 should be 'armv7s'");
}

- (void)test_arm64;
{
    XCTAssertEqualObjects(CDNameForCPUType(CPU_TYPE_ARM | CPU_ARCH_ABI64, CPU_SUBTYPE_ARM_ALL), @"arm64", @"The name for ARM 64-bit subtype CPU_SUBTYPE_ARM_ALL should be 'arm64'");
}

#pragma mark - Intel x86

- (void)test_i386;
{
    XCTAssertEqualObjects(CDNameForCPUType(CPU_TYPE_X86, CPU_SUBTYPE_386), @"i386", @"The name for X86 subtype CPU_SUBTYPE_386 should be 'i386'");
}

- (void)test_x86_64;
{
    XCTAssertEqualObjects(CDNameForCPUType(CPU_TYPE_X86_64, CPU_SUBTYPE_386), @"x86_64", @"The name for X86_64 subtype CPU_SUBTYPE_386 should be 'x86_64'");
}

- (void)test_x86_64_lib64;
{
    XCTAssertEqualObjects(CDNameForCPUType(CPU_TYPE_X86_64, CPU_SUBTYPE_386|CPU_SUBTYPE_LIB64), @"x86_64", @"The name for X86_64 subtype CPU_SUBTYPE_386 with capability bits should be 'x86_64'");
}

@end
