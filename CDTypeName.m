//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import "CDTypeName.h"

#import "rcsid.h"
#import <Foundation/Foundation.h>

RCS_ID("$Header: /Volumes/Data/tmp/Tools/class-dump/CDTypeName.m,v 1.1 2004/01/18 01:34:58 nygard Exp $");

@implementation CDTypeName

- (id)init;
{
    if ([super init] == nil)
        return nil;

    name = nil;
    templateTypes = [[NSMutableArray alloc] init];

    return self;
}

- (void)dealloc;
{
    [name release];

    [super dealloc];
}

- (NSString *)name;
{
    return name;
}

- (void)setName:(NSString *)newName;
{
    if (newName == name)
        return;

    [name release];
    name = [newName retain];
}

- (NSArray *)templateTypes;
{
    return templateTypes;
}

- (void)addTemplateType:(CDTypeName *)aTemplateType;
{
    [templateTypes addObject:aTemplateType];
}

- (NSString *)description;
{
    if ([templateTypes count] == 0)
        return name;

    return [NSString stringWithFormat:@"%@<%@>", name, [templateTypes componentsJoinedByString:@","]];
}

- (BOOL)isTemplateType;
{
    return [templateTypes count] > 0;
}

- (BOOL)isEqual:(id)otherObject;
{
    if ([otherObject isKindOfClass:[self class]] == NO)
        return NO;

    return [[self description] isEqual:[otherObject description]];
}

@end
