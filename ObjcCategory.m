//
// $Id: ObjcCategory.m,v 1.4.2.1 2003/09/05 21:25:54 nygard Exp $
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

#import "ObjcCategory.h"
#import "ObjcMethod.h"
#if NS_TARGET_MAJOR < 4 && !defined(__APPLE__)
#import <foundation/NSUtilities.h>
#endif
#import <stdio.h>

@implementation ObjcCategory

- initWithClassName:(NSString *)className categoryName:(NSString *)categoryName
{
    if ([super init] == nil)
        return nil;

    class_name = [className retain];
    category_name = [categoryName retain];
    class_methods = [[NSMutableArray array] retain];
    instance_methods = [[NSMutableArray array] retain];
    protocols = [[NSMutableArray array] retain];

    return self;
}

- (void) dealloc
{
    [class_name release];
    [category_name release];
    [class_methods release];
    [instance_methods release];
    [protocols release];
    
    [super dealloc];
}

//	begin wolf
- (NSString*) categoryName {
	return category_name;
}
//	end wolf

- (NSString *) sortableName
{
    return [NSString stringWithFormat:@"%@ %@", class_name, category_name];
}

- (void) addClassMethods:(NSArray *)newClassMethods
{
    [class_methods addObjectsFromArray:newClassMethods];
}

- (void) addInstanceMethods:(NSArray *)newInstanceMethods
{
    [instance_methods addObjectsFromArray:newInstanceMethods];
}

- (void) showDefinition:(int)flags
{
    NSEnumerator *enumerator;
    ObjcMethod *method;

    printf ("@interface %s(%s)\n", [class_name cString], [category_name cString]);

    if (flags & F_SORT_METHODS)
        enumerator = [[class_methods sortedArrayUsingSelector:@selector (orderByMethodName:)] objectEnumerator];
    else
        enumerator = [class_methods reverseObjectEnumerator];

    while (method = [enumerator nextObject])
    {
        [method showMethod:'+'];
        if (flags & F_SHOW_METHOD_ADDRESS)
        {
            printf ("\t// IMP=0x%08lx", [method address]);
        }
        printf ("\n");
    }

    if (flags & F_SORT_METHODS)
        enumerator = [[instance_methods sortedArrayUsingSelector:@selector (orderByMethodName:)] objectEnumerator];
    else
        enumerator = [instance_methods reverseObjectEnumerator];
    
    while (method = [enumerator nextObject])
    {
        [method showMethod:'-'];
        if (flags & F_SHOW_METHOD_ADDRESS)
        {
            printf ("\t// IMP=0x%08lx", [method address]);
        }
        printf ("\n");
    }

    printf ("@end\n\n");
}

@end
