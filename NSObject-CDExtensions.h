//
// $Id: NSObject-CDExtensions.h,v 1.2 2004/01/06 01:51:58 nygard Exp $
//

//  This file is part of class-dump, a utility for exmaing the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import <Foundation/NSObject.h>

@class NSArray;

@interface NSObject (CDExtensions)

- (void)performSelector:(SEL)aSelector withObjectsFromArray:(NSArray *)anArray;

@end
