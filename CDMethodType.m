// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2011 Steve Nygard.

#import "CDMethodType.h"

#import "CDType.h"

@implementation CDMethodType

- (id)initWithType:(CDType *)aType offset:(NSString *)anOffset;
{
    if ((self = [super init])) {
        type = [aType retain];
        offset = [anOffset retain];
    }

    return self;
}

- (void)dealloc;
{
    [type release];
    [offset release];

    [super dealloc];
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] type: %@, offset: %@", NSStringFromClass([self class]), self.type, self.offset];
}

#pragma mark -

@synthesize type;
@synthesize offset;

@end
