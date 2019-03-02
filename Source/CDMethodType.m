// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "CDMethodType.h"

#import "CDType.h"

@implementation CDMethodType
{
    CDType *_type;
    NSString *_offset;
}

- (id)initWithType:(CDType *)type offset:(NSString *)offset;
{
    if ((self = [super init])) {
        _type = type;
        _offset = offset;
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] type: %@, offset: %@", NSStringFromClass([self class]), self.type, self.offset];
}

@end
