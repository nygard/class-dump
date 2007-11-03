//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2007 Steve Nygard.  All rights reserved.

#import "NSError-CDExtensions.h"

@implementation NSError (CDExtensions)

// The normal methods confuse me, and it's late.
- (NSString *)myExplanation;
{
    NSString *str;

    str = [[self userInfo] objectForKey:@"explanation"];
    if (str != nil)
        return str;

    return [self description];
}

@end
