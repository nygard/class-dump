//
// $Id: ObjcIvar.h,v 1.3 1999/08/09 07:45:01 nygard Exp $
//

//
//  This file is a part of class-dump v2, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997, 1999  Steve Nygard
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

#if defined(__APPLE__) && defined (__MACH__)
#import <Foundation/Foundation.h>
#elif NS_TARGET_MAJOR >= 4
#import <Foundation/Foundation.h>
#else
#import <foundation/NSString.h>
#endif

@interface ObjcIvar : NSObject
{
    NSString *ivar_name;
    NSString *ivar_type;
    long ivar_offset;
}

- initWithName:(NSString *)ivarName type:(NSString *)ivarType offset:(long)ivarOffset;
- (void) dealloc;

- (NSString *) description;

- (long) offset;
- (void) showIvarAtLevel:(int)level;

@end
