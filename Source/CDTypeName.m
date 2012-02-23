// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDTypeName.h"

@implementation CDTypeName

- (id)init;
{
    if ((self = [super init])) {
        name = nil;
        templateTypes = [[NSMutableArray alloc] init];
        suffix = nil;
    }

    return self;
}

- (void)dealloc;
{
    [name release];
    [templateTypes release];
    [suffix release];

    [super dealloc];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone;
{
    CDTypeName *copy = [[CDTypeName alloc] init];
    copy.name = self.name;
    copy.suffix = self.suffix;
    
    for (CDTypeName *subtype in self.templateTypes) {
        CDTypeName *subcopy = [subtype copy];
        [copy.templateTypes addObject:subcopy];
        [subcopy release];
    }
    
    return copy;
}

#pragma mark -

- (BOOL)isEqual:(id)otherObject;
{
    if ([otherObject isKindOfClass:[self class]] == NO)
        return NO;
    
    return [[self description] isEqual:[otherObject description]];
}

#pragma mark - Debugging

- (NSString *)description;
{
    if ([self.templateTypes count] == 0)
        return name;
    
    if (self.suffix != nil)
        return [NSString stringWithFormat:@"%@<%@>%@", self.name, [self.templateTypes componentsJoinedByString:@", "], self.suffix];
    
    return [NSString stringWithFormat:@"%@<%@>", self.name, [self.templateTypes componentsJoinedByString:@", "]];
}

#pragma mark -

@synthesize name;
@synthesize templateTypes;
@synthesize suffix;

- (BOOL)isTemplateType;
{
    return [self.templateTypes count] > 0;
}

@end
