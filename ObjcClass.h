//
// $Id: ObjcClass.h,v 1.10 2002/12/19 06:13:19 nygard Exp $
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

#import "ObjcThing.h"

@class NSArray, NSMutableArray, NSMutableDictionary, NSString;

@interface ObjcClass : ObjcThing
{
    NSString *class_name;
    NSString *super_class_name;
    NSMutableArray *ivars;
    NSMutableArray *class_methods;
    NSMutableArray *instance_methods;
    NSMutableArray *protocol_names;
}

+ (NSMutableDictionary *)classDict;
+ (NSArray *)sortedClasses;

- (id)initWithClassName:(NSString *)className superClassName:(NSString *)superClassName;
- (void)dealloc;

- (NSString *)description;
- (NSString *)className;
- (NSArray *)protocolNames;

- (NSString *)sortableName;
- (NSString *)superClassName;

- (void)addIvars:(NSArray *)ivars;
- (void)addClassMethods:(NSArray *)newClassMethods;
- (void)addInstanceMethods:(NSArray *)newInstanceMethods;
- (void)addProtocolNames:(NSArray *)newProtocolNames;

- (void)showDefinition:(int)flags;

@end
