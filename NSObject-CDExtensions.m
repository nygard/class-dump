//
// $Id: NSObject-CDExtensions.m,v 1.2 2004/01/06 01:51:58 nygard Exp $
//

//  This file is part of class-dump, a utility for exmaing the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

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
