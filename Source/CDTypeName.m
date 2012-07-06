// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDTypeName.h"

BOOL global_shouldMangleTemplateTypes = NO;

@implementation CDTypeName
{
    NSString *name;
    NSMutableArray *templateTypes;
    NSString *suffix;
}

- (id)init;
{
    if ((self = [super init])) {
        name = nil;
        templateTypes = [[NSMutableArray alloc] init];
        suffix = nil;
    }

    return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone;
{
    CDTypeName *copy = [[CDTypeName allocWithZone:zone] init];
    copy.name = self.name;
    copy.suffix = self.suffix;
    
    for (CDTypeName *subtype in self.templateTypes) {
        CDTypeName *subcopy = [subtype copyWithZone:zone];
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
    if ([self.name isEqualToString:@"?"]) {
        return @"?";
    }

    NSMutableString *result = [NSMutableString string];

    [result setString:self.name];
    if ([self.templateTypes count] != 0)
        [result appendFormat:@"<%@>", [self.templateTypes componentsJoinedByString:@", "]];
    if (self.suffix != nil)
        [result appendFormat:@"%@", self.suffix];
    
    if (global_shouldMangleTemplateTypes) {
        NSString *legitCharacters = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                                     "abcdefghijklmnopqrstuvwxyz" "0123456789";

        NSCharacterSet *illegitCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:legitCharacters] invertedSet];
        return [[result componentsSeparatedByCharactersInSet:illegitCharacterSet] componentsJoinedByString:@"_"];
    } else {
        return [result description];
    }
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
