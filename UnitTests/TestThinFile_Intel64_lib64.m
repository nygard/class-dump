// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "TestThinFile_Intel64_lib64.h"

#import "CDFatArch.h"
#import "CDFatFile.h"
#import "CDMachOFile.h"

@implementation TestThinFile_Intel64_lib64
{
    CDMachOFile *_macho_x86_64;
}

- (void)setUp;
{
    [super setUp];
    
    // Set-up code here.
    _macho_x86_64 = [[CDMachOFile alloc] init];
    _macho_x86_64.cputype    = CPU_TYPE_X86_64;
    _macho_x86_64.cpusubtype = CPU_SUBTYPE_386 | CPU_SUBTYPE_LIB64; // For example, /Applications/Utilities/Grab.app on 10.8
}

- (void)tearDown;
{
    // Tear-down code here.
    _macho_x86_64  = nil;
    
    [super tearDown];
}

#pragma mark -

- (void)test_bestMatchIntel64;
{
    CDArch arch = { CPU_TYPE_X86_64, CPU_SUBTYPE_386 };
    
    BOOL result = [_macho_x86_64 bestMatchForArch:&arch];
    STAssertTrue(result,                                                                  @"Didn't find a best match for x86_64");
    STAssertTrue(arch.cputype == CPU_TYPE_X86_64,                                         @"Best match cputype should be CPU_TYPE_X86_64");
    STAssertTrue(arch.cpusubtype == (cpu_subtype_t)(CPU_SUBTYPE_386 | CPU_SUBTYPE_LIB64), @"Best match cpusubtype should be CPU_SUBTYPE_386");
}

- (void)test_machOFileWithArch_x86_64;
{
    CDArch arch = { CPU_TYPE_X86_64, CPU_SUBTYPE_386 };
    CDMachOFile *machOFile = [_macho_x86_64 machOFileWithArch:arch];
    STAssertNotNil(machOFile,                @"The Mach-O file shouldn't be nil", NULL);
    STAssertEquals(machOFile, _macho_x86_64, @"Didn't find correct Mach-O file", NULL);
}

- (void)test_machOFileWithArch_i386;
{
    CDArch arch = { CPU_TYPE_X86, CPU_SUBTYPE_386 };
    CDMachOFile *machOFile = [_macho_x86_64 machOFileWithArch:arch];
    STAssertNil(machOFile, @"The Mach-O file should be nil", NULL);
}

@end
