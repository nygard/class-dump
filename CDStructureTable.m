//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import "CDStructureTable.h"

#import "rcsid.h"
#import <Foundation/Foundation.h>

RCS_ID("$Header: /Volumes/Data/tmp/Tools/class-dump/CDStructureTable.m,v 1.1 2004/01/08 04:44:20 nygard Exp $");

@implementation CDStructureTable

- (id)init;
{
    if ([super init] == nil)
        return nil;

    structuresByName = [[NSMutableDictionary alloc] init];

    anonymousStructureCountsByType = [[NSMutableDictionary alloc] init];
    anonymousStructuresByType = [[NSMutableDictionary alloc] init];
    anonymousStructureNamesByType = [[NSMutableDictionary alloc] init];

    replacementTypes = [[NSMutableDictionary alloc] init];
    forcedTypedefs = [[NSMutableSet alloc] init];

    return self;
}

- (void)dealloc;
{
    [structuresByName release];

    [anonymousStructureCountsByType release];
    [anonymousStructuresByType release];
    [anonymousStructureNamesByType release];

    [replacementTypes release];
    [forcedTypedefs release];

    [super dealloc];
}

@end
