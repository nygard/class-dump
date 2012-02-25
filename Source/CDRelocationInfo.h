// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import <Foundation/Foundation.h>

#include <mach-o/reloc.h>

enum {
    CDRelocationInfoSize_8Bit  = 0,
    CDRelocationInfoSize_16Bit = 1,
    CDRelocationInfoSize_32Bit = 2,
    CDRelocationInfoSize_64Bit = 3,
};
typedef NSUInteger CDRelocationSize;

@interface CDRelocationInfo : NSObject

- (id)initWithInfo:(struct relocation_info)info;

- (NSString *)description;

@property (readonly) NSUInteger offset;
@property (readonly) CDRelocationSize size;
@property (readonly) uint32_t symbolnum;
@property (readonly) BOOL isExtern;

@end
