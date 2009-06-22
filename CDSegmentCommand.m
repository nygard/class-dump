//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2007  Steve Nygard

#import "CDSegmentCommand.h"

#include <mach-o/swap.h>
#import <Foundation/Foundation.h>
#import "CDFatFile.h"
#import "CDMachOFile.h"
#import "CDSection.h"

@implementation CDSegmentCommand

- (id)initWithDataCursor:(CDDataCursor *)cursor machOFile:(CDMachOFile *)aMachOFile;
{
    if ([super initWithDataCursor:cursor machOFile:aMachOFile] == nil)
        return nil;

    segmentCommand.cmd = [cursor readInt32];
    segmentCommand.cmdsize = [cursor readInt32];

    [cursor readBytesOfLength:16 intoBuffer:segmentCommand.segname];
    segmentCommand.vmaddr = [cursor readInt32];
    segmentCommand.vmsize = [cursor readInt32];
    segmentCommand.fileoff = [cursor readInt32];
    segmentCommand.filesize = [cursor readInt32];
    segmentCommand.maxprot = [cursor readInt32];
    segmentCommand.initprot = [cursor readInt32];
    segmentCommand.nsects = [cursor readInt32];
    segmentCommand.flags = [cursor readInt32];

    {
        char buf[17];

        memcpy(buf, segmentCommand.segname, 16);
        buf[16] = 0;
        name = [[NSString alloc] initWithBytes:buf length:strlen(buf) encoding:NSASCIIStringEncoding];
        if ([name length] >= 16) {
            NSLog(@"Notice: segment '%@' has length >= 16, which means it's not always null terminated.", name);
        }
    }

    {
        unsigned int index;

        sections = [[NSMutableArray alloc] init];
        for (index = 0; index < segmentCommand.nsects; index++) {
            CDSection *section;

            section = [[CDSection alloc] initWithDataCursor:cursor segment:self];
            [sections addObject:section];
            [section release];
        }
    }

    return self;
}

- (void)dealloc;
{
    [name release];
    [sections release];

    [super dealloc];
}

- (uint32_t)cmd;
{
    return segmentCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return segmentCommand.cmdsize;
}

- (NSString *)name;
{
    return name;
}

- (uint32_t)vmaddr;
{
    return segmentCommand.vmaddr;
}

- (uint32_t)fileoff;
{
    return segmentCommand.fileoff;
}

- (uint32_t)flags;
{
    return segmentCommand.flags;
}

- (NSArray *)sections;
{
    return sections;
}

- (BOOL)isProtected;
{
    return (segmentCommand.flags & SG_PROTECTED_VERSION_1) == SG_PROTECTED_VERSION_1;
}

- (NSString *)flagDescription;
{
    NSMutableArray *setFlags;
    unsigned long flags;

    setFlags = [NSMutableArray array];
    flags = [self flags];
    if (flags & SG_HIGHVM)
        [setFlags addObject:@"HIGHVM"];
    if (flags & SG_FVMLIB)
        [setFlags addObject:@"FVMLIB"];
    if (flags & SG_NORELOC)
        [setFlags addObject:@"NORELOC"];
    if (flags & SG_PROTECTED_VERSION_1)
        [setFlags addObject:@"PROTECTED_VERSION_1"];

    if ([setFlags count] == 0)
        return @"(none)";

    return [setFlags componentsJoinedByString:@" "];
}

- (NSString *)extraDescription;
{
    return [NSString stringWithFormat:@"name: '%@', vmaddr: 0x%08x - 0x%08x [0x%08x], offset: %d, flags: 0x%x (%@), nsects: %d, sections: %@",
                     name, segmentCommand.vmaddr, segmentCommand.vmaddr + segmentCommand.vmsize - 1, segmentCommand.vmsize, segmentCommand.fileoff,
                     [self flags], [self flagDescription], segmentCommand.nsects, sections];
}

#if 0
- (const void *)segmentDataBytes;
{
    return [[nonretainedMachOFile data] bytes] + [nonretainedMachOFile offset] + segmentCommand.fileoff;
}
#endif

// TODO (2003-12-06): Might want to make this a range.
- (BOOL)containsAddress:(uint32_t)vmaddr;
{
    return (vmaddr >= segmentCommand.vmaddr) && (vmaddr < segmentCommand.vmaddr + segmentCommand.vmsize);
}

- (CDSection *)sectionContainingAddress:(uint32_t)vmaddr;
{
    for (CDSection *section in sections) {
        if ([section containsAddress:vmaddr])
            return section;
    }

    return nil;
}

- (CDSection *)sectionWithName:(NSString *)aName;
{
    for (CDSection *section in sections) {
        if ([[section sectionName] isEqual:aName])
            return section;
    }

    return nil;
}

#if 0
- (uint32_t)segmentOffsetForVMAddr:(uint32_t)vmaddr;
{
    CDSection *section;

    section = [self sectionContainingAddress:vmaddr];
    NSLog(@"section: %@", section);
    return [section segmentOffsetForVMAddr:vmaddr];
}
#endif

- (uint32_t)fileOffsetForAddress:(uint32_t)address;
{
    return [[self sectionContainingAddress:address] fileOffsetForAddress:address];
}

- (void)appendToString:(NSMutableString *)resultString verbose:(BOOL)isVerbose;
{
    [super appendToString:resultString verbose:isVerbose];

    [resultString appendFormat:@"  segname %@\n", [self name]];
    [resultString appendFormat:@"   vmaddr 0x%08x\n", segmentCommand.vmaddr];
    [resultString appendFormat:@"   vmsize 0x%08x\n", segmentCommand.vmsize];
    [resultString appendFormat:@"  fileoff %d\n", segmentCommand.fileoff];
    [resultString appendFormat:@" filesize %d\n", segmentCommand.filesize];
    [resultString appendFormat:@"  maxprot 0x%08x\n", segmentCommand.maxprot];
    [resultString appendFormat:@" initprot 0x%08x\n", segmentCommand.initprot];
    [resultString appendFormat:@"   nsects %d\n", segmentCommand.nsects];

    if (isVerbose)
        [resultString appendFormat:@"    flags %@\n", [self flagDescription]];
    else
        [resultString appendFormat:@"    flags 0x%x\n", segmentCommand.flags];
}

- (void)writeSectionData;
{
    unsigned int index = 0;

    for (CDSection *section in sections) {
        [[section data] writeToFile:[NSString stringWithFormat:@"/tmp/%02d-%@", index, [section sectionName]] atomically:NO];
        index++;
    }
}

@end
