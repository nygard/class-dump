//
// $Id: ObjcCategory.h,v 1.5.2.1 2003/09/05 21:25:54 nygard Exp $
//

//
//  This file is a part of class-dump v2, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997, 1999, 2000  Steve Nygard
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
//
//  You may contact the author by:
//     e-mail:  nygard@omnigroup.com
//

#if NS_TARGET_MAJOR >= 4 || defined(__APPLE__)
#import <Foundation/Foundation.h>
#else
#import	<foundation/NSString.h>
#import	<foundation/NSArray.h>
#endif
#import "ObjcThing.h"

@interface ObjcCategory : ObjcThing
{
    NSString *class_name;
    NSString *category_name;
    NSMutableArray *class_methods;
    NSMutableArray *instance_methods;
    NSMutableArray *protocols;
}

- initWithClassName:(NSString *)className categoryName:(NSString *)categoryName;
- (void) dealloc;

//	begin wolf
- (NSString *) categoryName;
//	end wolf
- (NSString *) sortableName;

- (void) addClassMethods:(NSArray *)newClassMethods;
- (void) addInstanceMethods:(NSArray *)newInstanceMethods;

- (void) showDefinition:(int)flags;

@end
