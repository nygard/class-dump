// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDLCSegment64.h"

#import "CDSection64.h"

@implementation CDLCSegment64
{
    struct segment_command_64 segmentCommand;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        segmentCommand.cmd = [cursor readInt32];
        segmentCommand.cmdsize = [cursor readInt32];
        
        [cursor readBytesOfLength:16 intoBuffer:segmentCommand.segname];
        segmentCommand.vmaddr = [cursor readInt64];
        segmentCommand.vmsize = [cursor readInt64];
        segmentCommand.fileoff = [cursor readInt64];
        segmentCommand.filesize = [cursor readInt64];
        segmentCommand.maxprot = [cursor readInt32];
        segmentCommand.initprot = [cursor readInt32];
        segmentCommand.nsects = [cursor readInt32];
        segmentCommand.flags = [cursor readInt32];
        
        {
            char buf[17];
            
            memcpy(buf, segmentCommand.segname, 16);
            buf[16] = 0;
            NSString *str = [[NSString alloc] initWithBytes:buf length:strlen(buf) encoding:NSASCIIStringEncoding];
            [self setName:str];
            [str release];
        }

        NSMutableArray *_sections = [[NSMutableArray alloc] init];
        for (NSUInteger index = 0; index < segmentCommand.nsects; index++) {
            CDSection64 *section = [[CDSection64 alloc] initWithDataCursor:cursor segment:self];
            [_sections addObject:section];
            [section release];
        }
        self.sections = [[_sections copy] autorelease]; [_sections release];
    }

    return self;
}

#pragma mark -

- (uint32_t)cmd;
{
    return segmentCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return segmentCommand.cmdsize;
}

- (NSUInteger)vmaddr;
{
    return segmentCommand.vmaddr;
}

- (NSUInteger)fileoff;
{
    return segmentCommand.fileoff;
}

- (NSUInteger)filesize;
{
    return segmentCommand.filesize;
}

- (vm_prot_t)initprot;
{
    return segmentCommand.initprot;
}

- (uint32_t)flags;
{
    return segmentCommand.flags;
}

- (BOOL)containsAddress:(NSUInteger)address;
{
    return (address >= segmentCommand.vmaddr) && (address < segmentCommand.vmaddr + segmentCommand.vmsize);
}

- (NSString *)extraDescription;
{
    return [NSString stringWithFormat:@"addr: 0x%016lx", [self vmaddr]];
}

@end
