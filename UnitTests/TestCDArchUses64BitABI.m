// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import <XCTest/XCTest.h>

#import "CDFile.h"

@interface TestCDArchUses64BitABI : XCTestCase
@end

@implementation TestCDArchUses64BitABI

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

#pragma mark - Intel x86

- (void)test_i386;
{
    CDArch arch = { CPU_TYPE_X86, CPU_SUBTYPE_386 };
    XCTAssertFalse(CDArchUses64BitABI(arch), @"i386 does not use 64 bit ABI");
}

- (void)test_x86_64;
{
    CDArch arch = { CPU_TYPE_X86_64, CPU_SUBTYPE_386 };
    XCTAssertTrue(CDArchUses64BitABI(arch), @"x86_64 uses 64 bit ABI");
}

- (void)test_x86_64_lib64;
{
    CDArch arch = { CPU_TYPE_X86_64, CPU_SUBTYPE_386 | CPU_SUBTYPE_LIB64 };
    XCTAssertTrue(CDArchUses64BitABI(arch), @"x86_64 (with LIB64 capability bit) uses 64 bit ABI");
}

- (void)test_x86_64_plusOtherCapablity
{
    CDArch arch = { CPU_TYPE_X86_64 | 0x40000000, CPU_SUBTYPE_386 };
    XCTAssertTrue(CDArchUses64BitABI(arch), @"x86_64 (with other capability bit) uses 64 bit ABI");
}

@end
