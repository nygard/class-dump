//
// $Id: ObjcCategory.m,v 1.14 2004/01/06 01:51:59 nygard Exp $
//

//
//  This file is a part of class-dump v2, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard
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
//     e-mail:  class-dump at codethecode.com
//

#import "ObjcCategory.h"

#import <stdio.h>
#import <Foundation/Foundation.h>
#import "ObjcMethod.h"

@implementation ObjcCategory

- (id)initWithClassName:(NSString *)aClassName categoryName:(NSString *)aCategoryName;
{
    if ([super init] == nil)
        return nil;

    className = [aClassName retain];
    categoryName = [aCategoryName retain];
    classMethods = [[NSMutableArray alloc] init];
    instanceMethods = [[NSMutableArray alloc] init];
    protocols = [[NSMutableArray alloc] init];

    return self;
}

- (void)dealloc;
{
    [className release];
    [categoryName release];
    [classMethods release];
    [instanceMethods release];
    [protocols release];

    [super dealloc];
}

- (NSString *)categoryName;
{
    return categoryName;
}

- (NSString *)sortableName;
{
    return [NSString stringWithFormat:@"%@ %@", className, categoryName];
}

- (void)addClassMethods:(NSArray *)newClassMethods;
{
    [classMethods addObjectsFromArray:newClassMethods];
}

- (void)addInstanceMethods:(NSArray *)newInstanceMethods;
{
    [instanceMethods addObjectsFromArray:newInstanceMethods];
}

- (void)showDefinition:(int)flags;
{
    NSEnumerator *enumerator;
    ObjcMethod *method;

    printf("@interface %s(%s)\n", [className cString], [categoryName cString]);

    if (flags & F_SORT_METHODS)
        enumerator = [[classMethods sortedArrayUsingSelector:@selector (orderByMethodName:)] objectEnumerator];
    else
        enumerator = [classMethods reverseObjectEnumerator];

    while (method = [enumerator nextObject]) {
        [method showMethod:'+'];
        if (flags & F_SHOW_METHOD_ADDRESS)
            printf("\t// IMP=0x%08lx", [method address]);

        printf("\n");
    }

    if (flags & F_SORT_METHODS)
        enumerator = [[instanceMethods sortedArrayUsingSelector:@selector (orderByMethodName:)] objectEnumerator];
    else
        enumerator = [instanceMethods reverseObjectEnumerator];

    while (method = [enumerator nextObject]) {
        [method showMethod:'-'];
        if (flags & F_SHOW_METHOD_ADDRESS)
            printf("\t// IMP=0x%08lx", [method address]);

        printf("\n");
    }

    printf("@end\n\n");
}

@end
