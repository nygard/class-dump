// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "TestFatFile_Intel64_32.h"

#import "CDFatArch.h"
#import "CDFatFile.h"

@implementation TestFatFile_Intel64_32
{
    CDFatFile *_intel_64_32;
    CDFatArch *_arch_i386;
    CDFatArch *_arch_x86_64;
}

- (void)setUp;
{
    [super setUp];
    
    // Set-up code here.
    _intel_64_32 = [[CDFatFile alloc] init];

    _arch_x86_64 = [[CDFatArch alloc] initWithMachOFile:nil];
    _arch_x86_64.cpuType    = CPU_TYPE_X86_64;
    _arch_x86_64.cpuSubtype = CPU_SUBTYPE_386;
    [_intel_64_32 addArchitecture:_arch_x86_64];
    
    _arch_i386 = [[CDFatArch alloc] initWithMachOFile:nil];
    _arch_i386.cpuType    = CPU_TYPE_X86;
    _arch_i386.cpuSubtype = CPU_SUBTYPE_386;
    [_intel_64_32 addArchitecture:_arch_i386];
}

- (void)tearDown;
{
    // Tear-down code here.
    _intel_64_32 = nil;
    _arch_i386   = nil;
    _arch_x86_64 = nil;
    
    [super tearDown];
}

#pragma mark -

- (void)test_bestMatchIntel64;
{
    CDArch arch = { CPU_TYPE_X86_64, CPU_SUBTYPE_386 };
    
    BOOL result = [_intel_64_32 bestMatchForArch:&arch];
    STAssertTrue(result,                             @"Didn't find a best match for x86_64");
    STAssertTrue(arch.cputype == CPU_TYPE_X86_64,    @"Best match cputype should be CPU_TYPE_X86_64");
    STAssertTrue(arch.cpusubtype == CPU_SUBTYPE_386, @"Best match cpusubtype should be CPU_SUBTYPE_386");
}

#if 0
// We don't build 32-bit any more, so this test case shouldn't come up.
- (void)test_bestMatchIntel32;
{
    CDArch arch = { CPU_TYPE_X86, CPU_SUBTYPE_386 };
    
    BOOL result = [_intel_64_32 bestMatchForArch:&arch];
    STAssertTrue(result,                             @"Didn't find a best match for i386");
    STAssertTrue(arch.cputype == CPU_TYPE_X86,       @"Best match cputype should be CPU_TYPE_X86");
    STAssertTrue(arch.cpusubtype == CPU_SUBTYPE_386, @"Best match cpusubtype should be CPU_SUBTYPE_386");
}
#endif

@end
