// This file is part of APPNAME, SHORT DESCRIPTION
// Copyright (C) 2003 Steve Nygard.  All rights reserved.

#import "NSObject-CDExtensions.h"

#import <Foundation/Foundation.h>

@implementation NSObject (CDExtensions)

- (void)performSelector:(SEL)aSelector withObjectsFromArray:(NSArray *)anArray;
{
    int count, index;

    count = [anArray count];
    for (index = 0; index < count; index++) {
        [self performSelector:aSelector withObject:[anArray objectAtIndex:index]];
    }
}

@end
