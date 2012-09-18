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
    
    //struct fat_arch _fatArch;
    // This is essentially struct fat_arch, but this way our property accessors can be synthesized.
    cpu_type_t _cpuType;
    cpu_subtype_t _cpuSubtype;
    uint32_t _offset;
    uint32_t _size;
    uint32_t _align;
    
    CDMachOFile *_machOFile; // Lazily create this.
}

- (id)initWithMachOFile:(CDMachOFile *)machOFile;
{
    if ((self = [super init])) {
        _machOFile = machOFile;
        NSParameterAssert([machOFile.data length] < 0x100000000);
        
        _cpuType    = _machOFile.cputype;
        _cpuSubtype = _machOFile.cpusubtype;
        _offset     = 0; // Would be filled in when this is written to disk
        _size       = (uint32_t)[_machOFile.data length];
        _align      = 12; // 2**12 = 4096 (0x1000)
    }
    
    return self;
}

- (id)initWithDataCursor:(CDDataCursor *)cursor;
{
    if ((self = [super init])) {
        _cpuType    = [cursor readBigInt32];
        _cpuSubtype = [cursor readBigInt32];
        _offset     = [cursor readBigInt32];
        _size       = [cursor readBigInt32];
        _align      = [cursor readBigInt32];
        
        //NSLog(@"self: %@", self);
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"64 bit ABI? %d, cputype: 0x%08x, cpusubtype: 0x%08x, offset: 0x%08x (%8u), size: 0x%08x (%8u), align: 2^%u (%x), arch name: %@",
            self.uses64BitABI, _cpuType, _cpuSubtype, _offset, _offset, _size, _size,
            _align, 1 << _align, self.archName];
}

#pragma mark -

- (cpu_type_t)cpuType;
{
    return _cpuType;
}

- (cpu_type_t)maskedCPUType;
{
    return self.cpuType & ~CPU_ARCH_MASK;
}

- (cpu_subtype_t)cpuSubtype;
{
    return _cpuSubtype;
}

- (uint32_t)offset;
{
    return _offset;
}

- (uint32_t)size;
{
    return _size;
}

- (uint32_t)align;
{
    return _align;
}

- (BOOL)uses64BitABI;
{
    return CDArchUses64BitABI(self.arch);
}

@synthesize fatFile = nonretained_fatFile;

- (CDArch)arch;
{
    CDArch arch = { self.cpuType, self.cpuSubtype };

    return arch;
}

// Must not return nil.
- (NSString *)archName;
{
    return CDNameForCPUType(self.cpuType, self.cpuSubtype);
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
