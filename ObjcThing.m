//
// $Id: ObjcThing.m,v 1.9 2004/01/06 01:52:00 nygard Exp $
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

#import "ObjcThing.h"

#import <Foundation/Foundation.h>

@implementation ObjcThing

- (NSString *)sortableName;
{
    return @"";
}

- (void)showDefinition:(int)flags;
{
}

- (NSString *)superClass;
{
    return nil;
}

- (NSComparisonResult)orderByName:(ObjcThing *)otherThing;
{
    return [[self sortableName] compare:[otherThing sortableName]];
}

@end
