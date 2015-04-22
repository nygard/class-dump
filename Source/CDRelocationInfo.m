// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDRelocationInfo.h"

@implementation CDRelocationInfo
{
    struct relocation_info _rinfo;
}

- (id)initWithInfo:(struct relocation_info)info;
{
    if ((self = [super init])) {
        _rinfo = info;
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> addr/off: %08x, sym #: %5u, pcrel? %u, len: %u, extern? %u, type: %x",
            NSStringFromClass([self class]), self,
            _rinfo.r_address, _rinfo.r_symbolnum, _rinfo.r_pcrel, _rinfo.r_length, _rinfo.r_extern, _rinfo.r_type];
}

#pragma mark -

- (NSUInteger)offset;
{
    return _rinfo.r_address;
}

- (CDRelocationSize)size;
{
    return _rinfo.r_length;
}

- (uint32_t)symbolnum;
{
    return _rinfo.r_symbolnum;
}

- (BOOL)isExtern;
{
    return _rinfo.r_extern == 1;
}

@end
