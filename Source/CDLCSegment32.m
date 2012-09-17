// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDLCSegment32.h"

#import "CDSection32.h"

@implementation CDLCSegment32
{
    struct segment_command _segmentCommand;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        _segmentCommand.cmd     = [cursor readInt32];
        _segmentCommand.cmdsize = [cursor readInt32];
        
        [cursor readBytesOfLength:16 intoBuffer:_segmentCommand.segname];
        _segmentCommand.vmaddr   = [cursor readInt32];
        _segmentCommand.vmsize   = [cursor readInt32];
        _segmentCommand.fileoff  = [cursor readInt32];
        _segmentCommand.filesize = [cursor readInt32];
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
            CDSection32 *section = [[CDSection32 alloc] initWithDataCursor:cursor segment:self];
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

- (NSString *)extraDescription;
{
    return [NSString stringWithFormat:@"vmaddr: 0x%08x - 0x%08x [0x%08x], offset: %d, flags: 0x%x (%@), nsects: %d, sections: %@",
                     _segmentCommand.vmaddr, _segmentCommand.vmaddr + _segmentCommand.vmsize - 1, _segmentCommand.vmsize, _segmentCommand.fileoff,
                     self.flags, [self flagDescription], _segmentCommand.nsects, self.sections];
}

- (BOOL)containsAddress:(NSUInteger)address;
{
    return (address >= _segmentCommand.vmaddr) && (address < _segmentCommand.vmaddr + _segmentCommand.vmsize);
}

- (void)appendToString:(NSMutableString *)resultString verbose:(BOOL)isVerbose;
{
    [super appendToString:resultString verbose:isVerbose];
#if 0

    [resultString appendFormat:@"  segname %@\n",     [self name]];
    [resultString appendFormat:@"   vmaddr 0x%08x\n", segmentCommand.vmaddr];
    [resultString appendFormat:@"   vmsize 0x%08x\n", segmentCommand.vmsize];
    [resultString appendFormat:@"  fileoff %d\n",     segmentCommand.fileoff];
    [resultString appendFormat:@" filesize %d\n",     segmentCommand.filesize];
    [resultString appendFormat:@"  maxprot 0x%08x\n", segmentCommand.maxprot];
    [resultString appendFormat:@" initprot 0x%08x\n", segmentCommand.initprot];
    [resultString appendFormat:@"   nsects %d\n",     segmentCommand.nsects];

    if (isVerbose)
        [resultString appendFormat:@"    flags %@\n", [self flagDescription]];
    else
        [resultString appendFormat:@"    flags 0x%x\n", segmentCommand.flags];
#endif
}

@end
