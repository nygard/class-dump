//
// $Id: ObjcProtocol.m,v 1.13 2003/09/05 20:30:25 nygard Exp $
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
//     e-mail:  class-dump at codethecode.com
//

#import "ObjcProtocol.h"

#import <stdio.h>
#import <Foundation/Foundation.h>
#import "ObjcMethod.h"

@implementation ObjcProtocol

- (id)initWithProtocolName:(NSString *)aProtocolName;
{
    if ([super init] == nil)
        return nil;

    protocolName = [aProtocolName retain];
    protocolNames = [[NSMutableArray alloc] init];
    protocolMethods = [[NSMutableArray alloc] init];

    return self;
}

- (void)dealloc;
{
    [protocolName release];
    [protocolNames release];
    [protocolMethods release];

    [super dealloc];
}

- (NSString *)protocolName;
{
    return protocolName;
}

- (NSString *)sortableName;
{
    return protocolName;
}

- (void)addProtocolNames:(NSArray *)newProtocolNames;
{
    [protocolNames addObjectsFromArray:newProtocolNames];
}

- (void)addProtocolMethod:(ObjcMethod *)newMethod;
{
    [protocolMethods addObject:newMethod];
}

- (void)addProtocolMethods:(NSArray *)newProtocolMethods;
{
    [protocolMethods addObjectsFromArray:newProtocolMethods];
}

- (void)showDefinition:(int)flags;
{
    NSEnumerator *enumerator;
    ObjcMethod *method;

    printf("@protocol %s", [protocolName cString]);

    if ([protocolNames count] > 0) {
        NSString *aProtocolName;

        enumerator = [protocolNames objectEnumerator];
        printf(" <");
        aProtocolName = [enumerator nextObject];
        if (aProtocolName != nil) {
            printf("%s", [aProtocolName cString]);
            
            while (aProtocolName = [enumerator nextObject])
                printf(", %s", [aProtocolName cString]);
        }

        printf(">");
    }

    printf("\n");

    if (flags & F_SORT_METHODS)
        enumerator = [[protocolMethods sortedArrayUsingSelector:@selector (orderByMethodName:)] objectEnumerator];
    else
        enumerator = [protocolMethods objectEnumerator];

    while (method = [enumerator nextObject]) {
        [method showMethod:'-'];
        if (flags & F_SHOW_METHOD_ADDRESS)
            printf("\t// IMP=0x%08lx", [method address]);

        printf("\n");
    }

    printf("@end\n\n");
}

@end
