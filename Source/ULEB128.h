// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

// http://en.wikipedia.org/wiki/LEB128
// http://web.mit.edu/rhel-doc/3/rhel-as-en-3/uleb128.html
// uleb128 stands for "unsigned little endian base 128."
// This is a compact, variable length representation of numbers used by the DWARF symbolic debugging format.

// Top bit of byte is set until last byte.
// Other 7 bits are the "slice".
// Basically, it represents the low order bits 7 at a time, and can stop when the rest of the bits would be zero.
// This needs to modify ptr.

// For example, uleb with these bytes: e8 d7 15
// 0xe8 = 1110 1000
// 0xd7 = 1101 0111
// 0x15 = 0001 0101

//                 .... .... .... .... .... .... .... .... .... .... .... .... .... .... .... ....
// 0xe8 1 1101000  .... .... .... .... .... .... .... .... .... .... .... .... .... .... .110 1000
// 0xd7 1 1010111  .... .... .... .... .... .... .... .... .... .... .... .... ..10 1011 1110 1000
// 0x15 0 0010101  .... .... .... .... .... .... .... .... .... .... .... .... ..10 1011 1110 1000
// 0x15 0 0010101  .... .... .... .... .... .... .... .... .... .... ...0 0101 0110 1011 1110 1000
// Result is: 0x056be8
// So... 24 bits to encode 64 bits

uint64_t read_uleb128(const uint8_t **ptrptr, const uint8_t *end);

int64_t read_sleb128(const uint8_t **ptrptr, const uint8_t *end);
