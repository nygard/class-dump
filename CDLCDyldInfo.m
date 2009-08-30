// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import "CDLCDyldInfo.h"

#import "CDDataCursor.h"
#import "CDMachOFile.h"

#import "CDLCSegment.h"

// http://www.redhat.com/docs/manuals/enterprise/RHEL-4-Manual/gnu-assembler/uleb128.html
// uleb128 stands for "unsigned little endian base 128."
// This is a compact, variable length representation of numbers used by the DWARF symbolic debugging format. .sleb128

// Top bit of byte is set until last byte.
// Other 7 bits are the "slice".
// Basically, it represents the low order bits 7 at a time, and can stop when the rest of the bits would be zero.
// This needs to modify ptr.
static uint64_t read_uleb128(const uint8_t **ptrptr, const uint8_t *end)
{
    static uint32_t maxlen = 0;
    const uint8_t *ptr = *ptrptr;
    uint64_t result = 0;
    int bit = 0;

    //NSLog(@"read_uleb128()");
    do {
        uint64_t slice;

        if (ptr == end) {
            NSLog(@"Malformed uleb128");
            exit(88);
        }

        //NSLog(@"byte: %02x", *ptr);
        slice = *ptr & 0x7f;

        if (bit >= 64 || slice << bit >> bit != slice) {
            NSLog(@"uleb128 too big");
            exit(88);
        } else {
            result |= (slice << bit);
            bit += 7;
        }
    }
    while ((*ptr++ & 0x80) != 0);

    if (maxlen < ptr - *ptrptr) {
        NSMutableArray *byteStrs;
        const uint8_t *ptr2 = *ptrptr;

        byteStrs = [NSMutableArray array];
        do {
            [byteStrs addObject:[NSString stringWithFormat:@"%02x", *ptr2]];
        } while (++ptr2 < ptr);
        NSLog(@"max uleb length now: %u (%@)", ptr - *ptrptr, [byteStrs componentsJoinedByString:@" "]);
        maxlen = ptr - *ptrptr;
    }

    *ptrptr = ptr;
    return result;
}

static NSString *CDRebaseTypeString(uint8_t type)
{
    switch (type) {
      case REBASE_TYPE_POINTER: return @"Pointer";
      case REBASE_TYPE_TEXT_ABSOLUTE32: return @"Absolute 32";
      case REBASE_TYPE_TEXT_PCREL32: return @"PC rel 32";
    }

    return @"Unknown";
}

// Need acces to: list of segments

@implementation CDLCDyldInfo

- (id)initWithDataCursor:(CDDataCursor *)cursor machOFile:(CDMachOFile *)aMachOFile;
{
    if ([super initWithDataCursor:cursor machOFile:aMachOFile] == nil)
        return nil;

    dyldInfoCommand.cmd = [cursor readInt32];
    dyldInfoCommand.cmdsize = [cursor readInt32];

    dyldInfoCommand.rebase_off = [cursor readInt32];
    dyldInfoCommand.rebase_size = [cursor readInt32];
    dyldInfoCommand.bind_off = [cursor readInt32];
    dyldInfoCommand.bind_size = [cursor readInt32];
    dyldInfoCommand.weak_bind_off = [cursor readInt32];
    dyldInfoCommand.weak_bind_size = [cursor readInt32];
    dyldInfoCommand.lazy_bind_off = [cursor readInt32];
    dyldInfoCommand.lazy_bind_size = [cursor readInt32];
    dyldInfoCommand.export_off = [cursor readInt32];
    dyldInfoCommand.export_size = [cursor readInt32];

    NSLog(@"       cmdsize: %08x", dyldInfoCommand.cmdsize);
    NSLog(@"    rebase_off: %08x", dyldInfoCommand.rebase_off);
    NSLog(@"   rebase_size: %08x", dyldInfoCommand.rebase_size);
    NSLog(@"      bind_off: %08x", dyldInfoCommand.bind_off);
    NSLog(@"     bind_size: %08x", dyldInfoCommand.bind_size);
    NSLog(@" weak_bind_off: %08x", dyldInfoCommand.weak_bind_off);
    NSLog(@"weak_bind_size: %08x", dyldInfoCommand.weak_bind_size);
    NSLog(@" lazy_bind_off: %08x", dyldInfoCommand.lazy_bind_off);
    NSLog(@"lazy_bind_size: %08x", dyldInfoCommand.lazy_bind_size);
    NSLog(@"    export_off: %08x", dyldInfoCommand.export_off);
    NSLog(@"   export_size: %08x", dyldInfoCommand.export_size);

    [self logRebaseInfo];
    exit(99);

    return nil;
}

- (uint32_t)cmd;
{
    return dyldInfoCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return dyldInfoCommand.cmdsize;
}

// address, slide, type
// slide is constant throughout the loop
- (void)logRebaseInfo;
{
    const uint8_t *start, *end, *ptr;
    BOOL isDone = NO;
    NSArray *segments;
    uint64_t address;
    uint8_t type;
    NSUInteger rebaseCount = 0;

    segments = [nonretainedMachOFile segments];
    NSLog(@"segments: %@", segments);
    NSParameterAssert([segments count] > 0);

    address = [[segments objectAtIndex:0] vmaddr];
    type = 0;

    NSLog(@"----------------------------------------------------------------------");
    NSLog(@"rebase_off: %u, rebase_size: %u", dyldInfoCommand.rebase_off, dyldInfoCommand.rebase_size);
    start = [nonretainedMachOFile machODataBytes] + dyldInfoCommand.rebase_off;
    end = start + dyldInfoCommand.rebase_size;

    NSLog(@"address: %016lx", address);
    ptr = start;
    while ((ptr < end) && isDone == NO) {
        uint8_t immediate, opcode;

        immediate = *ptr & REBASE_IMMEDIATE_MASK;
        opcode = *ptr & REBASE_OPCODE_MASK;
        ptr++;

        switch (opcode) {
          case REBASE_OPCODE_DONE:
              //NSLog(@"REBASE_OPCODE: DONE");
              isDone = YES;
              break;
          case REBASE_OPCODE_SET_TYPE_IMM:
              //NSLog(@"REBASE_OPCODE: SET_TYPE_IMM,                       type = 0x%x // %@", immediate, CDRebaseTypeString(immediate));
              type = immediate;
              break;
          case REBASE_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB: {
              uint64_t val = read_uleb128(&ptr, end);

              //NSLog(@"REBASE_OPCODE: SET_SEGMENT_AND_OFFSET_ULEB,        segment index: %u, offset: %016lx", immediate, val);
              NSParameterAssert(immediate < [segments count]);
              address = [[segments objectAtIndex:immediate] vmaddr] + val;
              //NSLog(@"    address: %016lx", address);
              break;
          }
          case REBASE_OPCODE_ADD_ADDR_ULEB: {
              uint64_t val = read_uleb128(&ptr, end);

              //NSLog(@"REBASE_OPCODE: ADD_ADDR_ULEB,                      addr += %016lx", val);
              address += val;
              //NSLog(@"    address: %016lx", address);
              break;
          }
          case REBASE_OPCODE_ADD_ADDR_IMM_SCALED:
              // I expect sizeof(uintptr_t) == sizeof(uint64_t)
              //NSLog(@"REBASE_OPCODE: ADD_ADDR_IMM_SCALED,                addr += %u * %u", immediate, sizeof(uint64_t));
              address += immediate * sizeof(uint64_t);
              //NSLog(@"    address: %016lx", address);
              break;
          case REBASE_OPCODE_DO_REBASE_IMM_TIMES: {
              uint32_t index;

              //NSLog(@"REBASE_OPCODE: DO_REBASE_IMM_TIMES,                count: %u", immediate);
              for (index = 0; index < immediate; index++) {
                  [self rebaseAddress:address type:type];
                  address += sizeof(uint64_t);
              }
              rebaseCount += immediate;
              break;
          }
          case REBASE_OPCODE_DO_REBASE_ULEB_TIMES: {
              uint64_t count, index;

              count = read_uleb128(&ptr, end);

              //NSLog(@"REBASE_OPCODE: DO_REBASE_ULEB_TIMES,               count: 0x%016lx", count);
              for (index = 0; index < count; index++) {
                  [self rebaseAddress:address type:type];
                  address += sizeof(uint64_t);
              }
              rebaseCount += count;
              break;
          }
          case REBASE_OPCODE_DO_REBASE_ADD_ADDR_ULEB: {
              uint64_t val;

              val = read_uleb128(&ptr, end);
              // --------------------------------------------------------:
              //NSLog(@"REBASE_OPCODE: DO_REBASE_ADD_ADDR_ULEB,            addr += 0x%016lx", val);
              [self rebaseAddress:address type:type];
              address += sizeof(uint64_t) + val;
              rebaseCount++;
              break;
          }
          case REBASE_OPCODE_DO_REBASE_ULEB_TIMES_SKIPPING_ULEB: {
              uint64_t count, skip, index;

              count = read_uleb128(&ptr, end);
              skip = read_uleb128(&ptr, end);
              //NSLog(@"REBASE_OPCODE: DO_REBASE_ULEB_TIMES_SKIPPING_ULEB, count: %016lx, skip: %016lx", count, skip);
              for (index = 0; index < count; index++) {
                  [self rebaseAddress:address type:type];
                  address += sizeof(uint64_t) + skip;
              }
              rebaseCount += count;
              break;
          }
          default:
              NSLog(@"Unknown opcode op: %x, imm: %x", opcode, immediate);
        }
    }

    NSLog(@"    ptr: %p, end: %p, bytes left over: %u", ptr, end, end - ptr);
    NSLog(@"    rebaseCount: %lu", rebaseCount);
    NSLog(@"----------------------------------------------------------------------");
}

- (void)rebaseAddress:(uint64_t)address type:(uint8_t)type;
{
    //NSLog(@"    Rebase 0x%016lx, type: %x (%@)", address, type, CDRebaseTypeString(type));
}

@end
