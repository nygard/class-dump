// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import <XCTest/XCTest.h>

#import "CDFatArch.h"
#import "CDFatFile.h"
#import "CDMachOFile.h"

@interface TestFatFile_Intel64_32 : XCTestCase
@end

@implementation TestFatFile_Intel64_32
{
    CDFatFile *_fatFile;
    CDFatArch *_arch_i386;
    CDFatArch *_arch_x86_64;
    CDMachOFile *_macho_i386;
    CDMachOFile *_macho_x86_64;
}

- (void)setUp;
{
    [super setUp];
    
    // Set-up code here.
    _fatFile = [[CDFatFile alloc] init];
    
    _macho_x86_64 = [[CDMachOFile alloc] init];
    _macho_x86_64.cputype    = CPU_TYPE_X86_64;
    _macho_x86_64.cpusubtype = CPU_SUBTYPE_386;
    
    _arch_x86_64 = [[CDFatArch alloc] initWithMachOFile:_macho_x86_64];
    [_fatFile addArchitecture:_arch_x86_64];
    
    _macho_i386 = [[CDMachOFile alloc] init];
    _macho_i386.cputype    = CPU_TYPE_X86;
    _macho_i386.cpusubtype = CPU_SUBTYPE_386;
    
    _arch_i386 = [[CDFatArch alloc] initWithMachOFile:_macho_i386];
    [_fatFile addArchitecture:_arch_i386];
}

- (void)tearDown;
{
    // Tear-down code here.
    _fatFile      = nil;
    _arch_i386    = nil;
    _arch_x86_64  = nil;
    _macho_i386   = nil;
    _macho_x86_64 = nil;
    
    [super tearDown];
}

#pragma mark -

- (void)test_bestMatchIntel64;
{
    CDArch arch = { CPU_TYPE_X86_64, CPU_SUBTYPE_386 };
    
    BOOL result = [_fatFile bestMatchForArch:&arch];
    XCTAssertTrue(result,                             @"Didn't find a best match for x86_64");
    XCTAssertTrue(arch.cputype == CPU_TYPE_X86_64,    @"Best match cputype should be CPU_TYPE_X86_64");
    XCTAssertTrue(arch.cpusubtype == CPU_SUBTYPE_386, @"Best match cpusubtype should be CPU_SUBTYPE_386");
}

#if 0
// We don't build 32-bit any more, so this test case shouldn't come up.
- (void)test_bestMatchIntel32;
{
    CDArch arch = { CPU_TYPE_X86, CPU_SUBTYPE_386 };
    
    BOOL result = [_intel_64_32 bestMatchForArch:&arch];
    XCTAssertTrue(result,                             @"Didn't find a best match for i386");
    XCTAssertTrue(arch.cputype == CPU_TYPE_X86,       @"Best match cputype should be CPU_TYPE_X86");
    XCTAssertTrue(arch.cpusubtype == CPU_SUBTYPE_386, @"Best match cpusubtype should be CPU_SUBTYPE_386");
}
#endif

- (void)test_machOFileWithArch_x86_64;
{
    CDArch arch = { CPU_TYPE_X86_64, CPU_SUBTYPE_386 };
    CDMachOFile *machOFile = [_fatFile machOFileWithArch:arch];
    XCTAssertNotNil(machOFile,               @"The Mach-O file shouldn't be nil", NULL);
    XCTAssertEqual(machOFile, _macho_x86_64, @"Didn't find correct Mach-O file", NULL);
}

- (void)test_machOFileWithArch_i386;
{
    CDArch arch = { CPU_TYPE_X86, CPU_SUBTYPE_386 };
    CDMachOFile *machOFile = [_fatFile machOFileWithArch:arch];
    XCTAssertNotNil(machOFile,             @"The Mach-O file shouldn't be nil", NULL);
    XCTAssertEqual(machOFile, _macho_i386, @"Didn't find correct Mach-O file");
}

@end
