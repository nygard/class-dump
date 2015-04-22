// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDTypeName.h"

@implementation CDTypeName
{
    NSString *_name;
    NSMutableArray *_templateTypes;
    NSString *_suffix;
}

- (id)init;
{
    if ((self = [super init])) {
        _name = nil;
        _templateTypes = [[NSMutableArray alloc] init];
        _suffix = nil;
    }

    return self;
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
    if ([self.templateTypes count] == 0) {
        return self.name ? self.name : @"";
    }
    
    if (self.suffix != nil)
        return [NSString stringWithFormat:@"%@<%@>%@", self.name, [self.templateTypes componentsJoinedByString:@", "], self.suffix];
    
    return [NSString stringWithFormat:@"%@<%@>", self.name, [self.templateTypes componentsJoinedByString:@", "]];
}

#pragma mark -

- (BOOL)isTemplateType;
{
    return [self.templateTypes count] > 0;
}

@end
