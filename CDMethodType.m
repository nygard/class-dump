// This file is part of APPNAME, SHORT DESCRIPTION
// Copyright (C) 2003 Steve Nygard.  All rights reserved.

#import "CDMethodType.h"

#import <Foundation/Foundation.h>
#import "CDType.h"

@implementation CDMethodType

- (id)initWithType:(CDType *)aType offset:(NSString *)anOffset;
{
    if ([super init] == nil)
        return nil;

    type = [aType retain];
    offset = [anOffset retain];

    return self;
}

- (void)dealloc;
{
    [type release];
    [offset release];

    [super dealloc];
}

- (CDType *)type;
{
    return type;
}

- (NSString *)offset;
{
    return offset;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] type: %@, offset: %@", NSStringFromClass([self class]), type, offset];
}

@end
