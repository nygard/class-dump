//
// $Id: CDTopologicalSortProtocol.h,v 1.2 2004/01/06 01:51:57 nygard Exp $
//

//  This file is part of class-dump, a utility for exmaing the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

@class NSArray, NSString;

@protocol CDTopologicalSort
- (NSString *)identifier;
- (NSArray *)dependancies;
@end
