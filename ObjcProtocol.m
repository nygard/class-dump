//
// $Id: ObjcProtocol.m,v 1.5 2002/12/19 05:44:47 nygard Exp $
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

#import "ObjcProtocol.h"
#import <stdio.h>

@implementation ObjcProtocol

- initWithProtocolName:(NSString *)protocolName
{
    if ([super init] == nil)
        return nil;

    protocol_name = [protocolName retain];
    protocol_names = [[NSMutableArray array] retain];
    protocol_methods = [[NSMutableArray array] retain];

    return self;
}

- (void) dealloc
{
    [protocol_name release];
    [protocol_names release];
    [protocol_methods release];

    [super dealloc];
}

- (NSString *) protocolName
{
    return protocol_name;
}

- (NSString *) sortableName
{
    return protocol_name;
}

- (void) addProtocolNames:(NSArray *)newProtocolNames
{
    [protocol_names addObjectsFromArray:newProtocolNames];
}

- (void) addProtocolMethod:(ObjcMethod *)newMethod
{
    [protocol_methods addObject:newMethod];
}

- (void) addProtocolMethods:(NSArray *)newProtocolMethods
{
    [protocol_methods addObjectsFromArray:newProtocolMethods];
}

- (void) showDefinition:(int)flags
{
    NSEnumerator *enumerator;
    ObjcMethod *method;
    NSString *protocolName;

    printf ("@protocol %s", [protocol_name cString]);

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

    printf ("\n");

    if (flags & F_SORT_METHODS)
        enumerator = [[protocol_methods sortedArrayUsingSelector:@selector (orderByMethodName:)] objectEnumerator];
    else
        enumerator = [protocol_methods objectEnumerator];

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
