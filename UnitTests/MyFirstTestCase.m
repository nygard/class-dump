//
//  MyFirstTestCase.m
//  class-dump
//
//  Created by Steve Nygard on 2007-11-02.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MyFirstTestCase.h"


@implementation MyFirstTestCase

- (void)testSomething;
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    STAssertEquals(32, 32,
                   @"Centigrade freezing point should be 32, but was %d instead!",
                   33);
}

@end
