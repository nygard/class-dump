//
// $Id: NSArray-Extensions.h,v 1.4 2004/01/06 02:31:44 nygard Exp $
//

//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import <Foundation/NSArray.h>

@interface NSArray (CDExtensions)

- (NSArray *)reversedArray;
- (NSArray *)arrayByMappingSelector:(SEL)aSelector;

@end
