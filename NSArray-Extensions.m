//  This file is part of class-dump, a utility for exmaing the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import "NSArray-Extensions.h"

#import "rcsid.h"
#import <Foundation/Foundation.h>

RCS_ID("$Header: /Volumes/Data/tmp/Tools/class-dump/NSArray-Extensions.m,v 1.4 2004/01/06 02:18:19 nygard Exp $");

@implementation NSArray (CDExtensions)

- (NSArray *)reversedArray;
{
    return [[self reverseObjectEnumerator] allObjects];
}

- (NSArray *)arrayByMappingSelector:(SEL)aSelector;
{
    NSMutableArray *newArray;
    int count, index;

    newArray = [NSMutableArray array];
    count = [self count];
    for (index = 0; index < count; index++)
        [newArray addObject:[[self objectAtIndex:index] performSelector:aSelector]];

    return newArray;
}

@end
