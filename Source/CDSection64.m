// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDSection64.h"

#include <mach-o/loader.h>
#import "CDMachOFileDataCursor.h"
#import "CDMachOFile.h"
#import "CDLCSegment64.h"

@implementation CDSection64
{
    __weak CDLCSegment64 *nonretained_segment;
    
    struct section_64 section;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor segment:(CDLCSegment64 *)aSegment;
{
    if ((self = [super init])) {
        nonretained_segment = aSegment;
        
        [cursor readBytesOfLength:16 intoBuffer:section.sectname];
        [cursor readBytesOfLength:16 intoBuffer:section.segname];
        section.addr = [cursor readInt64];
        section.size = [cursor readInt64];
        section.offset = [cursor readInt32];
        section.align = [cursor readInt32];
        section.reloff = [cursor readInt32];
        section.nreloc = [cursor readInt32];
        section.flags = [cursor readInt32];
        section.reserved1 = [cursor readInt32];
        section.reserved2 = [cursor readInt32];
        section.reserved3 = [cursor readInt32];
        
        // These aren't guaranteed to be null terminated.  Witness __cstring_object in __OBJC segment
        char buf[17];
        NSString *str;
        
        memcpy(buf, section.segname, 16);
        buf[16] = 0;
        str = [[NSString alloc] initWithBytes:buf length:strlen(buf) encoding:NSASCIIStringEncoding];
        [self setSegmentName:str];
        
        memcpy(buf, section.sectname, 16);
        buf[16] = 0;
        str = [[NSString alloc] initWithBytes:buf length:strlen(buf) encoding:NSASCIIStringEncoding];
        [self setSectionName:str];
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> segment; '%@', section: '%-16s', addr: %016llx, size: %016llx",
            NSStringFromClass([self class]), self,
            self.segmentName, [self.sectionName UTF8String],
            section.addr, section.size];
}

#pragma mark -

@synthesize segment = nonretained_segment;

- (CDMachOFile *)machOFile;
{
    return [[self segment] machOFile];
}

- (NSUInteger)addr;
{
    return section.addr;
}

- (NSUInteger)size;
{
    return section.size;
}

- (void)loadData;
{
    if (self.hasLoadedData == NO) {
        self.data = [[NSData alloc] initWithBytes:[[self.segment.machOFile machOData] bytes] + section.offset length:section.size];
        self.hasLoadedData = YES;
    }
}

- (BOOL)containsAddress:(NSUInteger)address;
{
    return (address >= section.addr) && (address < section.addr + section.size);
}

- (NSUInteger)fileOffsetForAddress:(NSUInteger)address;
{
    NSParameterAssert([self containsAddress:address]);
    return section.offset + address - section.addr;
}

@end
