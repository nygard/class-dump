//
// $Id: MappedFile.m,v 1.1 1999/07/31 03:32:27 nygard Exp $
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

#import "MappedFile.h"
#if NS_TARGET_MAJOR < 4
#import <foundation/NSArray.h>
#import <foundation/NSException.h>
#import <foundation/NSPathUtilities.h>
#import <foundation/NSUtilities.h>

@interface NSString (Foundation4PathCompatibility)
- (NSArray *)pathComponents;
@end

@implementation NSString (Foundation4PathCompatibility)
- (NSArray *)pathComponents
{
   return [self componentsSeparatedByString:@"/"];
}
@end

#endif

#include <stdio.h>
#include <libc.h>
#include <ctype.h>

@implementation MappedFile

// Will map filename into memory.  If filename is a directory with specific suffixes, treat the directory as a wrapper.

- initWithFilename:(NSString *)aFilename
{
    NSString *standardPath;
#if (NS_TARGET_MAJOR >= 4)
    NSMutableSet *wrappers = [NSMutableSet set];
#else
    // for foundation 3.x (less efficient than a set but at least it works...)
    NSMutableArray *wrappers = [NSMutableArray array];
#endif
    if ([super init] == nil)
        return nil;

    standardPath = [aFilename stringByStandardizingPath];

    [wrappers addObject:@"app"];
    [wrappers addObject:@"framework"];
    [wrappers addObject:@"bundle"];
    [wrappers addObject:@"palette"];

    if ([wrappers containsObject:[standardPath pathExtension]] == YES)
    {
        standardPath = [self pathToMainFileOfWrapper:standardPath];
    }

    data = [[NSData dataWithContentsOfMappedFile:standardPath] retain];
    if (data == nil)
    {
        NSLog (@"Couldn't map file: %@", standardPath);
        return nil;
    }

    filename = [standardPath retain];

    return self;
}

- (void) dealloc
{
    [data release];
    [filename release];

    [super dealloc];
}

- (NSString *) filename
{
    return filename;
}

- (const void *) data
{
    return [data bytes];
}

// How does this handle something ending in "/"?

- (NSString *) pathToMainFileOfWrapper:(NSString *)path
{
    NSRange range;
    NSMutableString *tmp;
    NSString *extension;
    NSString *base;

    base = [[path pathComponents] lastObject];
    NSAssert (base != nil, @"No base.");
    
    extension = [NSString stringWithFormat:@".%@", [base pathExtension]];

    tmp = [NSMutableString stringWithFormat:@"%@/%@", path, base];
    range = [tmp rangeOfString:extension options:NSBackwardsSearch];
    [tmp deleteCharactersInRange:range];

    return tmp;
}

@end
