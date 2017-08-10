// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import <XCTest/XCTest.h>

#import "CDFile.h"

@interface TestCDArchFromName : XCTestCase
@end

@implementation TestCDArchFromName

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
    CDArch arch = CDArchFromName(@"armv6");
    XCTAssertEqual(arch.cputype,    CPU_TYPE_ARM,       @"The cputype for 'armv6' should be ARM");
    XCTAssertEqual(arch.cpusubtype, CPU_SUBTYPE_ARM_V6, @"The cpusubtype for 'armv6' should be ARM_V6");
}

- (void)test_armv7;
{
    CDArch arch = CDArchFromName(@"armv7");
    XCTAssertEqual(arch.cputype,    CPU_TYPE_ARM,       @"The cputype for 'armv7' should be ARM");
    XCTAssertEqual(arch.cpusubtype, CPU_SUBTYPE_ARM_V7, @"The cpusubtype for 'armv7' should be ARM_V7");
}

- (void)test_armv7s;
{
    CDArch arch = CDArchFromName(@"armv7s");
    XCTAssertEqual(arch.cputype,    CPU_TYPE_ARM,       @"The cputype for 'armv7s' should be ARM");
    XCTAssertEqual(arch.cpusubtype, 11,                 @"The cpusubtype for 'armv7s' should be 11");
}

- (void)test_arm64;
{
    CDArch arch = CDArchFromName(@"arm64");
    XCTAssertEqual(arch.cputype,    CPU_TYPE_ARM | CPU_ARCH_ABI64, @"The cputype for 'arm64' should be ARM with 64-bit mask");
    XCTAssertEqual(arch.cpusubtype, CPU_SUBTYPE_ARM_ALL,           @"The cpusubtype for 'arm64' should be CPU_SUBTYPE_ARM_ALL");
}

#pragma mark - Intel x86

- (void)test_i386;
{
    CDArch arch = CDArchFromName(@"i386");
    XCTAssertEqual(arch.cputype,    CPU_TYPE_X86,       @"The cputype for 'i386' should be X86");
    XCTAssertEqual(arch.cpusubtype, CPU_SUBTYPE_386,    @"The cpusubtype for 'i386' should be 386");
}

- (void)test_x86_64;
{
    CDArch arch = CDArchFromName(@"x86_64");
    XCTAssertEqual(arch.cputype,    CPU_TYPE_X86_64,    @"The cputype for 'x86_64' should be X86_64");
    XCTAssertEqual(arch.cpusubtype, CPU_SUBTYPE_386,    @"The cpusubtype for 'x86_64' should be 386");
}

@end
