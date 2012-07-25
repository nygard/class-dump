// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDFatArch.h"

#include <mach-o/fat.h>
#import "CDDataCursor.h"
#import "CDFatFile.h"
#import "CDMachOFile.h"

@implementation CDFatArch
{
    __weak CDFatFile *nonretained_fatFile;
    
    struct fat_arch _fatArch;
    
    CDMachOFile *_machOFile; // Lazily create this.
}

- (id)initWithDataCursor:(CDDataCursor *)cursor;
{
    if ((self = [super init])) {
        nonretained_fatFile = nil;
        
        _fatArch.cputype = [cursor readBigInt32];
        _fatArch.cpusubtype = [cursor readBigInt32];
        _fatArch.offset = [cursor readBigInt32];
        _fatArch.size = [cursor readBigInt32];
        _fatArch.align = [cursor readBigInt32];
        
#if 0
        NSLog(@"type: 64 bit? %d, 0x%x, subtype: 0x%x, offset: 0x%x, size: 0x%x, align: 0x%x",
              [self uses64BitABI], fatArch.cputype, fatArch.cpusubtype, fatArch.offset, fatArch.size, fatArch.align);
#endif
        
        _machOFile = nil;
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"64 bit ABI? %d, cputype: 0x%08x, cpusubtype: 0x%08x, offset: 0x%08x (%8u), size: 0x%08x (%8u), align: 2^%d (%d), arch name: %@",
            [self uses64BitABI], _fatArch.cputype, _fatArch.cpusubtype, _fatArch.offset, _fatArch.offset, _fatArch.size, _fatArch.size,
            _fatArch.align, 1 << _fatArch.align, self.archName];
}

#pragma mark -

- (cpu_type_t)cpuType;
{
    return _fatArch.cputype;
}

- (cpu_type_t)maskedCPUType;
{
    return _fatArch.cputype & ~CPU_ARCH_MASK;
}

- (cpu_subtype_t)cpuSubtype;
{
    return _fatArch.cpusubtype;
}

- (uint32_t)offset;
{
    return _fatArch.offset;
}

- (uint32_t)size;
{
    return _fatArch.size;
}

- (uint32_t)align;
{
    return _fatArch.align;
}

- (BOOL)uses64BitABI;
{
    return CDArchUses64BitABI((CDArch){ .cputype = _fatArch.cputype, .cpusubtype = _fatArch.cpusubtype });
}

@synthesize fatFile = nonretained_fatFile;

- (CDArch)arch;
{
    CDArch arch = { _fatArch.cputype, _fatArch.cpusubtype };

    return arch;
}

// Must not return nil.
- (NSString *)archName;
{
    return CDNameForCPUType(_fatArch.cputype, _fatArch.cpusubtype);
}

- (CDMachOFile *)machOFile;
{
    if (_machOFile == nil) {
        _machOFile = [CDFile fileWithData:self.fatFile.data archOffset:_fatArch.offset archSize:_fatArch.size filename:self.fatFile.filename searchPathState:self.fatFile.searchPathState];
    }

    return _machOFile;
}

- (NSData *)machOData;
{
    return [[NSData alloc] initWithBytes:(uint8_t *)[[self.fatFile data] bytes] + _fatArch.offset length:_fatArch.size];
}

@end
