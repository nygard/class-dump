// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2009 Steve Nygard.  All rights reserved.

#import <Foundation/Foundation.h>

#include <mach-o/reloc.h>

enum {
    CDRelocationInfoLength8Bit = 0,
    CDRelocationInfoLength16Bit = 1,
    CDRelocationInfoLength32Bit = 2,
    CDRelocationInfoLength64Bit = 3,
};
typedef NSUInteger CDRelocationSize;

@interface CDRelocationInfo : NSObject
{
    struct relocation_info rinfo;
}

- (id)initWithInfo:(struct relocation_info)info;

- (NSUInteger)offset;
- (CDRelocationSize)size;
- (uint32_t)symbolnum;
- (BOOL)isExtern;

- (NSString *)description;

@end
