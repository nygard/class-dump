//
// $Id: ObjcClass.m,v 1.9 2002/12/19 06:13:19 nygard Exp $
//

//
//  This file is a part of class-dump v2, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997, 1999, 2000, 2002  Steve Nygard
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

#import "ObjcClass.h"

#import <Foundation/Foundation.h>
#include <stdio.h>
#include "datatypes.h"
#import "ObjcIvar.h"
#import "ObjcMethod.h"

@implementation ObjcClass

+ (NSMutableDictionary *)classDict;
{
    static NSMutableDictionary *classDict = nil;

    if (classDict == nil)
        classDict = [[NSMutableDictionary alloc] init];

    return classDict;
}

+ (NSArray *)sortedClasses;
{
    NSMutableArray *classes;
    NSMutableDictionary *classDict;
    BOOL done;

    classDict = [ObjcClass classDict];
    classes = [[[NSMutableArray alloc] init] autorelease];

    do {
        NSEnumerator *enumerator = [classDict objectEnumerator];
        id object;

        done = true;
        while (object = [enumerator nextObject]) {
            if (![classDict objectForKey:[object superClassName]]) {
                [classes addObject:object];
                [classDict removeObjectForKey:[object className]];
                done = false;
            }
        }
    } while (!done);

    return classes;
}

- (id)initWithClassName:(NSString *)className superClassName:(NSString *)superClassName;
{
    if ([super init] == nil)
        return nil;

    class_name = [className retain];
    super_class_name = [superClassName retain];
    ivars = [[NSMutableArray array] retain];
    class_methods = [[NSMutableArray array] retain];
    instance_methods = [[NSMutableArray array] retain];
    protocol_names = [[NSMutableArray array] retain];

    [[ObjcClass classDict] setObject:self forKey:className];

    return self;
}

- (void)dealloc;
{
    [class_name release];
    [super_class_name release];
    [ivars release];
    [class_methods release];
    [instance_methods release];
    [protocol_names release];
    
    [super dealloc];
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"@interface %@:%@ {\n%@\n}\n%@\n%@",
                     class_name, super_class_name, ivars, class_methods, instance_methods];
}

- (NSString *)className;
{
    return class_name;
}

- (NSArray *)protocolNames;
{
    return protocol_names;
}

- (NSString *)sortableName;
{
    return class_name;
}

- (NSString *)superClassName;
{
    return super_class_name;
}

- (void)addIvars:(NSArray *)newIvars;
{
    [ivars addObjectsFromArray:newIvars];
}

- (void)addClassMethods:(NSArray *)newClassMethods;
{
    [class_methods addObjectsFromArray:newClassMethods];
}

- (void)addInstanceMethods:(NSArray *)newInstanceMethods;
{
    [instance_methods addObjectsFromArray:newInstanceMethods];
}

- (void)addProtocolNames:(NSArray *)newProtocolNames;
{
    [protocol_names addObjectsFromArray:newProtocolNames];
}

- (void)showDefinition:(int)flags;
{
    NSEnumerator *enumerator;
    ObjcIvar *ivar;
    ObjcMethod *method;
    NSString *protocolName;

    printf ("@interface %s", [class_name cString]);
    if (super_class_name != nil)
        printf (":%s", [super_class_name cString]);

    if ([protocol_names count] > 0)
    {
        enumerator = [protocol_names objectEnumerator];
        printf (" <");
        protocolName = [enumerator nextObject];
        if (protocolName != nil)
        {
            printf ("%s", [protocolName cString]);
            
            while (protocolName = [enumerator nextObject])
            {
                printf (", %s", [protocolName cString]);
            }
        }

        printf (">");
    }

    printf ("\n{\n");

    enumerator = [ivars objectEnumerator];
    while (ivar = [enumerator nextObject])
    {
        [ivar showIvarAtLevel:2];
        if (flags & F_SHOW_IVAR_OFFSET)
        {
            printf ("\t// %ld = 0x%lx", [ivar offset], [ivar offset]);
        }
        printf ("\n");
    }

    //printf ("%s\n", [[ivars description] cString]);
    printf ("}\n\n");

    //NSLog (@"class_methods: %@", class_methods);

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

    printf ("\n@end\n\n");
}

@end
