//
// $Id: CDSectionInfo.m,v 1.4 2003/12/05 06:49:42 nygard Exp $
//

//
//  This file is a part of class-dump v2, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997, 1998, 1999, 2000, 2001, 2002  Steve Nygard
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

#import "CDSectionInfo.h"

#import <Foundation/Foundation.h>

@implementation CDSectionInfo

- (id)initWithFilename:(NSString *)aFilename
                  name:(NSString *)aName
               section:(struct section *)aSection
                 start:(void *)aStart
                vmaddr:(long)aVMAddr
                  size:(long)aSize;
{
    if ([super init] == nil)
        return nil;

    filename = [aFilename retain];
    name = [aName retain];
    section = aSection;
    start = aStart;
    vmaddr = aVMAddr;
    size = aSize;

    return self;
}

- (void)dealloc;
{
    [filename release];
    [name release];

    [super dealloc];
}

- (NSString *)filename;
{
    return filename;
}

- (NSString *)name;
{
    return name;
}

- (struct section *)section;
{
    return section;
}

- (void *)start;
{
    return start;
}

- (long)vmaddr;
{
    return vmaddr;
}

- (long)size;
{
    return size;
}

- (long)endAddress;
{
    return vmaddr + size;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"%10lx to %10lx [size 0x%08ld] %@ of %s",
                     vmaddr, [self endAddress], size,
                     [name stringByPaddingToLength:16 withString:@" " startingAtIndex:0],
                     [filename fileSystemRepresentation]];
}

- (BOOL)containsAddress:(long)anAddress;
{
    if (anAddress >= vmaddr && anAddress < vmaddr + size)
        return YES;

    return NO;
}

- (void *)translateAddress:(long)anAddress;
{
    return start + anAddress - vmaddr;
}

- (NSComparisonResult)ascendingCompareByAddress:(CDSectionInfo *)otherSection;
{
    long otherAddress;

    otherAddress = [otherSection vmaddr];
    if (vmaddr < otherAddress)
        return NSOrderedAscending;
    else if (vmaddr == otherAddress) {
        long otherSize;

        otherSize = [otherSection size];
        if (size < otherSize)
            return NSOrderedAscending;
        else if (size == otherSize)
            return NSOrderedSame;
    }

    return NSOrderedDescending;
}

@end
