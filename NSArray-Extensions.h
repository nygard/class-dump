//
// $Id: NSArray-Extensions.h,v 1.3 2004/01/06 01:51:58 nygard Exp $
//

//  This file is part of class-dump, a utility for exmaing the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import <Foundation/NSArray.h>

@interface NSArray (CDExtensions)

- (NSArray *)reversedArray;
- (NSArray *)arrayByMappingSelector:(SEL)aSelector;

@end
