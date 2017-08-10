// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import <XCTest/XCTest.h>

#import "CDFatArch.h"
#import "CDFatFile.h"
#import "CDMachOFile.h"

@interface TestFatFile_armv7_v7s : XCTestCase
@end

@implementation TestFatFile_armv7_v7s
{
    CDFatFile *_fatFile;
    CDFatArch *_arch_v7;
    CDFatArch *_arch_v7s;
    CDMachOFile *_macho_v7;
    CDMachOFile *_macho_v7s;
}

- (void)setUp;
{
    [super setUp];
    
    // Set-up code here.
    _fatFile = [[CDFatFile alloc] init];
    
    _macho_v7 = [[CDMachOFile alloc] init];
    _macho_v7.cputype    = CPU_TYPE_ARM;
    _macho_v7.cpusubtype = CPU_SUBTYPE_ARM_V7;

    _arch_v7 = [[CDFatArch alloc] initWithMachOFile:_macho_v7];
    [_fatFile addArchitecture:_arch_v7];

    _macho_v7s = [[CDMachOFile alloc] init];
    _macho_v7s.cputype    = CPU_TYPE_ARM;
    _macho_v7s.cpusubtype = 11;

    _arch_v7s = [[CDFatArch alloc] initWithMachOFile:_macho_v7s];
    [_fatFile addArchitecture:_arch_v7s];
}

- (void)tearDown;
{
    // Tear-down code here.
    _fatFile   = nil;
    _arch_v7   = nil;
    _arch_v7s  = nil;
    _macho_v7  = nil;
    _macho_v7s = nil;
    
    [super tearDown];
}

#pragma mark -

- (void)test_machOFileWithArch_armv7;
{
    CDArch arch = { CPU_TYPE_ARM, CPU_SUBTYPE_ARM_V7 };
    CDMachOFile *machOFile = [_fatFile machOFileWithArch:arch];
    XCTAssertNotNil(machOFile,            @"The Mach-O file shouldn't be nil", NULL);
    XCTAssertEqual(machOFile, _macho_v7,  @"Didn't find correct Mach-O file");
}

- (void)test_machOFileWithArch_armv7s;
{
    CDArch arch = { CPU_TYPE_ARM, 11 };
    CDMachOFile *machOFile = [_fatFile machOFileWithArch:arch];
    XCTAssertNotNil(machOFile,             @"The Mach-O file shouldn't be nil");
    XCTAssertEqual(machOFile, _macho_v7s,  @"Didn't find correct Mach-O file");
}

@end
