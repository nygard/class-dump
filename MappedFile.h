//
// $Id: MappedFile.h,v 1.12 2004/01/06 01:51:57 nygard Exp $
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

#include <sys/types.h>
#include <sys/stat.h>

#import <Foundation/NSObject.h>

@class NSData, NSString;

// And most of this could be done with NSData - initWithContentsOfMappedFile:

@interface MappedFile : NSObject
{
    NSString *installName;
    NSString *filename;
    NSData *data;
}

+ (void)initialize;

+ (BOOL)debug;
+ (void)setDebug:(BOOL)flag;

- (id)initWithFilename:(NSString *)aFilename;
- (void)dealloc;

- (NSString *)installName;
- (NSString *)filename;
- (const void *)data;

+ (BOOL)isWrapperAtPath:(NSString *)path;
+ (NSString *)pathToMainFileOfWrapper:(NSString *)wrapperPath;

+ (NSString *)adjustUserSuppliedPath:(NSString *)path;
+ (NSString *)adjustInstallName:(NSString *)installName;

+ (NSString *)adjustedFrameworkPath:(NSString *)path;

@end
