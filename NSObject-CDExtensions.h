// This file is part of APPNAME, SHORT DESCRIPTION
// Copyright (C) 2003 Steve Nygard.  All rights reserved.

#import <Foundation/NSObject.h>

@class NSArray;

@interface NSObject (CDExtensions)

- (void)performSelector:(SEL)aSelector withObjectsFromArray:(NSArray *)anArray;

@end
