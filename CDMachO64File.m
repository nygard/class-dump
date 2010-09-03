// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDMachO64File.h"

#import "CDMachOFileDataCursor.h"

@implementation CDMachO64File

- (id)initWithData:(NSData *)someData archOffset:(NSUInteger)anOffset archSize:(NSUInteger)aSize filename:(NSString *)aFilename searchPathState:(CDSearchPathState *)aSearchPathState;
{
    CDDataCursor *cursor;

    if ([super initWithData:someData archOffset:anOffset archSize:aSize filename:aFilename searchPathState:aSearchPathState] == nil)
        return nil;

    cursor = [[CDDataCursor alloc] initWithData:someData offset:archOffset];
    header.magic = [cursor readBigInt32];

    //NSLog(@"(testing macho 64) magic: 0x%x", header.magic);
    if (header.magic == MH_MAGIC_64) {
        byteOrder = CDByteOrderBigEndian;
    } else if (header.magic == MH_CIGAM_64) {
        byteOrder = CDByteOrderLittleEndian;
    } else {
        [cursor release];
        [self release];
        return nil;
    }

    //NSLog(@"byte order: %d", byteOrder);

    header.cputype = [cursor readBigInt32];
    header.cpusubtype = [cursor readBigInt32];
    header.filetype = [cursor readBigInt32];
    header.ncmds = [cursor readBigInt32];
    header.sizeofcmds = [cursor readBigInt32];
    header.flags = [cursor readBigInt32];
    header.reserved = [cursor readBigInt32];

    [cursor release];

    if (byteOrder == CDByteOrderLittleEndian) {
        header.cputype = OSSwapInt32(header.cputype);
        header.cpusubtype = OSSwapInt32(header.cpusubtype);
        header.filetype = OSSwapInt32(header.filetype);
        header.ncmds = OSSwapInt32(header.ncmds);
        header.sizeofcmds = OSSwapInt32(header.sizeofcmds);
        header.flags = OSSwapInt32(header.flags);
    }

    //NSLog(@"cputype: 0x%08x", header.cputype);
    //NSLog(@"cpusubtype: 0x%08x", header.cpusubtype);
    //NSLog(@"filetype: 0x%08x", header.filetype);
    //NSLog(@"ncmds: %u", header.ncmds);
    //NSLog(@"sizeofcmds: %u", header.sizeofcmds);
    //NSLog(@"flags: 0x%08x", header.flags);
    //NSLog(@"reserved: 0x%08x", header.reserved);

    _flags.uses64BitABI = CDArchUses64BitABI((CDArch){ .cputype = header.cputype, .cpusubtype = header.cpusubtype });
    header.cputype &= ~CPU_ARCH_MASK;

    CDMachOFileDataCursor *fileCursor = [[CDMachOFileDataCursor alloc] initWithFile:self offset:sizeof(struct mach_header_64)];
    [self _readLoadCommands:fileCursor count:header.ncmds];
    [fileCursor release];

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


- (BOOL)bestMatchForLocalArch:(CDArch *)archPtr;
{
    if (archPtr != NULL) {
        archPtr->cputype = header.cputype;
        archPtr->cpusubtype = header.cpusubtype;
    }

    return YES;
}

@end
