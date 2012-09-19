// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDLCSegment64.h"

#import "CDSection64.h"

@implementation CDLCSegment64
{
    struct segment_command_64 _segmentCommand;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        _segmentCommand.cmd     = [cursor readInt32];
        _segmentCommand.cmdsize = [cursor readInt32];
        
        [cursor readBytesOfLength:16 intoBuffer:_segmentCommand.segname];
        _segmentCommand.vmaddr   = [cursor readInt64];
        _segmentCommand.vmsize   = [cursor readInt64];
        _segmentCommand.fileoff  = [cursor readInt64];
        _segmentCommand.filesize = [cursor readInt64];
        _segmentCommand.maxprot  = [cursor readInt32];
        _segmentCommand.initprot = [cursor readInt32];
        _segmentCommand.nsects   = [cursor readInt32];
        _segmentCommand.flags    = [cursor readInt32];
        
        {
            char buf[17];
            
            memcpy(buf, _segmentCommand.segname, 16);
            buf[16] = 0;
            NSString *str = [[NSString alloc] initWithBytes:buf length:strlen(buf) encoding:NSASCIIStringEncoding];
            [self setName:str];
        }

        NSMutableArray *_sections = [[NSMutableArray alloc] init];
        for (NSUInteger index = 0; index < _segmentCommand.nsects; index++) {
            CDSection64 *section = [[CDSection64 alloc] initWithDataCursor:cursor segment:self];
            [_sections addObject:section];
        }
        self.sections = [_sections copy]; 
    }

    return self;
}

#pragma mark -

- (uint32_t)cmd;
{
    return _segmentCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return _segmentCommand.cmdsize;
}

- (NSUInteger)vmaddr;
{
    return _segmentCommand.vmaddr;
}

- (NSUInteger)fileoff;
{
    return _segmentCommand.fileoff;
}

- (NSUInteger)filesize;
{
    return _segmentCommand.filesize;
}

- (vm_prot_t)initprot;
{
    return _segmentCommand.initprot;
}

- (uint32_t)flags;
{
    return _segmentCommand.flags;
}

- (BOOL)containsAddress:(NSUInteger)address;
{
    return (address >= _segmentCommand.vmaddr) && (address < _segmentCommand.vmaddr + _segmentCommand.vmsize);
}

- (NSString *)extraDescription;
{
    return [NSString stringWithFormat:@"addr: 0x%016lx", [self vmaddr]];
}

@end
