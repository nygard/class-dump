//
// $Id: CDTopologicalSortProtocol.h,v 1.3 2004/01/06 02:31:43 nygard Exp $
//

//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

@class NSArray, NSString;

@protocol CDTopologicalSort
- (NSString *)identifier;
- (NSArray *)dependancies;
@end
