//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import "CDMethodType.h"

#import "rcsid.h"
#import <Foundation/Foundation.h>
#import "CDType.h"

RCS_ID("$Header: /Volumes/Data/tmp/Tools/class-dump/CDMethodType.m,v 1.10 2004/01/16 00:18:20 nygard Exp $");

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

- (void)registerStructuresWithObject:(id <CDStructureRegistration>)anObject phase:(int)phase;
{
    [type phase:phase registerStructuresWithObject:anObject usedInMethod:YES];
}

@end
