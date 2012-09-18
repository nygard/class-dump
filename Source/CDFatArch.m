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

- (id)initWithMachOFile:(CDMachOFile *)machOFile;
{
    if ((self = [super init])) {
        _machOFile = machOFile;
        NSParameterAssert([machOFile.data length] < 0x100000000);
        
        _fatArch.cputype    = _machOFile.cputype;
        _fatArch.cpusubtype = _machOFile.cpusubtype;
        _fatArch.offset     = 0; // Would be filled in when this is written to disk
        _fatArch.size       = (uint32_t)[_machOFile.data length];
        _fatArch.align      = 12; // 2**12 = 4096 (0x1000)
    }
    
    return self;
}

- (id)initWithDataCursor:(CDDataCursor *)cursor;
{
    if ((self = [super init])) {
        _fatArch.cputype    = [cursor readBigInt32];
        _fatArch.cpusubtype = [cursor readBigInt32];
        _fatArch.offset     = [cursor readBigInt32];
        _fatArch.size       = [cursor readBigInt32];
        _fatArch.align      = [cursor readBigInt32];
        
        //NSLog(@"self: %@", self);
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"64 bit ABI? %d, cputype: 0x%08x, cpusubtype: 0x%08x, offset: 0x%08x (%8u), size: 0x%08x (%8u), align: 2^%u (%x), arch name: %@",
            self.uses64BitABI, _fatArch.cputype, _fatArch.cpusubtype, _fatArch.offset, _fatArch.offset, _fatArch.size, _fatArch.size,
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
    return CDArchUses64BitABI(self.arch);
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
        NSData *data = [NSData dataWithBytesNoCopy:((uint8_t *)[self.fatFile.data bytes] + self.offset) length:self.size freeWhenDone:NO];
        _machOFile = [[CDMachOFile alloc] initWithData:data filename:self.fatFile.filename searchPathState:self.fatFile.searchPathState];
    }

    return _machOFile;
}

@end
