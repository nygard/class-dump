//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2007  Steve Nygard

#import "MyFirstTestCase.h"

@implementation MyFirstTestCase

- (void)testSomething;
{
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    STAssertEquals(32, 32,
                   @"Centigrade freezing point should be 32, but was %d instead!",
                   33);
}

#if 0
+ (id)defaultTestSuite;
{
    NSLog(@"Here...");
    return nil;
}
#endif

@end
