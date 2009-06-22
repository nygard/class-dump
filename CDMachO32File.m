//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2009 Steve Nygard.  All rights reserved.

#import "CDMachO32File.h"

@implementation CDMachO32File

- (id)initWithData:(NSData *)_data;
{
    CDDataCursor *cursor;

    if ([super initWithData:_data] == nil)
        return nil;

    cursor = [[CDDataCursor alloc] initWithData:_data];
    header.magic = [cursor readLittleInt32];

    NSLog(@"(testing macho 32) magic: 0x%x", header.magic);
    if (header.magic == MH_MAGIC) {
        byteOrder = CDByteOrderLittleEndian;
    } else if (header.magic == MH_CIGAM) {
        byteOrder = CDByteOrderBigEndian;
    } else {
        NSLog(@"Not a 32-bit MachO file.");
        [cursor release];
        [self release];
        return nil;
    }

    NSLog(@"byte order: %d", byteOrder);
    [cursor setByteOrder:byteOrder];

    header.cputype = [cursor readInt32];
    NSLog(@"cputype: 0x%08x", header.cputype);

    header.cpusubtype = [cursor readInt32];
    header.filetype = [cursor readInt32];
    header.ncmds = [cursor readInt32];
    header.sizeofcmds = [cursor readInt32];
    header.flags = [cursor readInt32];

    NSLog(@"cpusubtype: 0x%08x", header.cpusubtype);
    NSLog(@"filetype: 0x%08x", header.filetype);
    NSLog(@"ncmds: %u", header.ncmds);
    NSLog(@"sizeofcmds: %u", header.sizeofcmds);
    NSLog(@"flags: 0x%08x", header.flags);

    _flags.uses64BitABI = (header.cputype & CPU_ARCH_MASK) == CPU_ARCH_ABI64;
    header.cputype &= ~CPU_ARCH_MASK;

    [self _readLoadCommands:cursor count:header.ncmds];

    return self;
}

- (uint32_t)magic;
{
    return header.magic;
}

- (cpu_type_t)cputype;
{
    return header.cputype;
}

- (cpu_subtype_t)cpusubtype;
{
    return header.cpusubtype;
}

- (uint32_t)filetype;
{
    return header.filetype;
}

- (uint32_t)flags;
{
    return header.flags;
}

- (NSString *)bestMatchForLocalArch;
{
    return CDNameForCPUType(header.cputype, header.cpusubtype);
}

@end
