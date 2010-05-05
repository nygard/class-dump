// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDTypeName.h"

@implementation CDTypeName

- (id)init;
{
    if ([super init] == nil)
        return nil;

    name = nil;
    templateTypes = [[NSMutableArray alloc] init];
    suffix = nil;

    return self;
}

- (void)dealloc;
{
    [name release];
    [templateTypes release];
    [suffix release];

    [super dealloc];
}

@synthesize name;

- (NSArray *)templateTypes;
{
    return templateTypes;
}

- (void)addTemplateType:(CDTypeName *)aTemplateType;
{
    [templateTypes addObject:aTemplateType];
}

@synthesize suffix;

- (NSString *)description;
{
    if ([templateTypes count] == 0)
        return name;

    if (suffix != nil)
        return [NSString stringWithFormat:@"%@<%@>%@", name, [templateTypes componentsJoinedByString:@", "], suffix];

    return [NSString stringWithFormat:@"%@<%@>", name, [templateTypes componentsJoinedByString:@", "]];
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

- (id)copyWithZone:(NSZone *)zone;
{
    CDTypeName *copy;

    copy = [[CDTypeName alloc] init];
    [copy setName:name];
    [copy setSuffix:suffix];

    for (CDTypeName *subtype in templateTypes) {
        CDTypeName *subcopy;

        subcopy = [subtype copy];
        [copy addTemplateType:subcopy];
        [subcopy release];
    }

    return copy;
}

@end
