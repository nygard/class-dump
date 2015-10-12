// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#include <mach-o/reloc.h>

typedef enum : NSUInteger {
    CDRelocationInfoSize_8Bit  = 0,
    CDRelocationInfoSize_16Bit = 1,
    CDRelocationInfoSize_32Bit = 2,
    CDRelocationInfoSize_64Bit = 3,
} CDRelocationSize;

@interface CDRelocationInfo : NSObject

- (id)initWithInfo:(struct relocation_info)info;

@property (nonatomic, readonly) NSUInteger offset;
@property (nonatomic, readonly) CDRelocationSize size;
@property (nonatomic, readonly) uint32_t symbolnum;
@property (nonatomic, readonly) BOOL isExtern;

@end
