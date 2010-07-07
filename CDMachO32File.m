// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDMachO32File.h"

#import "CDObjectiveC1Processor.h"
#import "CDObjectiveC2Processor32.h"

@implementation CDMachO32File

- (id)initWithData:(NSData *)someData offset:(NSUInteger)anOffset filename:(NSString *)aFilename searchPathState:(CDSearchPathState *)aSearchPathState;
{
    CDDataCursor *cursor;

    if ([super initWithData:someData offset:anOffset filename:aFilename searchPathState:aSearchPathState] == nil)
        return nil;

    cursor = [[CDDataCursor alloc] initWithData:someData];
    //NSLog(@"CDMachO32File - setting offset to %08x", offset);
    [cursor setOffset:offset];
    header.magic = [cursor readLittleInt32];

    //NSLog(@"(testing macho 32) magic: 0x%x", header.magic);
    if (header.magic == MH_MAGIC) {
        byteOrder = CDByteOrderLittleEndian;
    } else if (header.magic == MH_CIGAM) {
        byteOrder = CDByteOrderBigEndian;
    } else {
        [cursor release];
        [self release];
        return nil;
    }

    //NSLog(@"byte order: %d", byteOrder);
    [cursor setByteOrder:byteOrder];

    header.cputype = [cursor readInt32];
    //NSLog(@"cputype: 0x%08x", header.cputype);

    header.cpusubtype = [cursor readInt32];
    header.filetype = [cursor readInt32];
    header.ncmds = [cursor readInt32];
    header.sizeofcmds = [cursor readInt32];
    header.flags = [cursor readInt32];

    //NSLog(@"cpusubtype: 0x%08x", header.cpusubtype);
    //NSLog(@"filetype: 0x%08x", header.filetype);
    //NSLog(@"ncmds: %u", header.ncmds);
    //NSLog(@"sizeofcmds: %u", header.sizeofcmds);
    //NSLog(@"flags: 0x%08x", header.flags);

    _flags.uses64BitABI = CDArchUses64BitABI((CDArch){ .cputype = header.cputype, .cpusubtype = header.cpusubtype });
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

- (BOOL)bestMatchForLocalArch:(CDArch *)archPtr;
{
    if (archPtr != NULL) {
        archPtr->cputype = header.cputype;
        archPtr->cpusubtype = header.cpusubtype;
    }

    return YES;
}

- (Class)processorClass;
{
    if ([self hasObjectiveC2Data])
        return [CDObjectiveC2Processor32 class];

    return [CDObjectiveC1Processor class];
}

@end
