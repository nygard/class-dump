//
// $Id: ObjcMethod.m,v 1.1 1999/07/31 03:32:26 nygard Exp $
//

//
//  This file is a part of class-dump v2, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997  Steve Nygard
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
//     e-mail:  nygard@telusplanet.net
//

#import "ObjcMethod.h"
#include "datatypes.h"

@implementation ObjcMethod

- initWithMethodName:(NSString *)methodName type:(NSString *)methodType
{
    if ([self initWithMethodName:methodName type:methodType address:0] == nil)
        return nil;
    
    is_protocol_method = YES;

    return self;
}

- initWithMethodName:(NSString *)methodName type:(NSString *)methodType address:(long)methodAddress
{
    [super init];

    method_name = [methodName retain];
    method_type = [methodType retain];
    method_address = methodAddress;
    is_protocol_method = NO;

    return self;
}

- (void) dealloc
{
    [method_name release];
    [method_type release];
    
    [super dealloc];
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"%@/%@\t// %x", method_name, method_type, method_address];
}

- (NSString *) methodName
{
    return method_name;
}

- (long) address
{
    return method_address;
}

- (void) showMethod:(char)prefix
{
    format_method (prefix, [method_name cString], [method_type cString]);
}

- (NSComparisonResult) orderByMethodName:(ObjcMethod *)otherMethod
{
    return [method_name compare:[otherMethod methodName]];
}


@end
