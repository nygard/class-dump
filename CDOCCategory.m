// This file is part of APPNAME, SHORT DESCRIPTION
// Copyright (C) 2003 Steve Nygard.  All rights reserved.

#import "CDOCCategory.h"

#import <Foundation/Foundation.h>
#import "CDOCMethod.h"
#import "NSArray-Extensions.h"

@implementation CDOCCategory

- (id)init;
{
    if ([super init] == nil)
        return nil;

    return self;
}

- (void)dealloc;
{
    [name release];
    [className release];
    [protocols release];
    [classMethods release];
    [instanceMethods release];

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

- (NSString *)className;
{
    return className;
}

- (void)setClassName:(NSString *)newClassName;
{
    if (newClassName == className)
        return;

    [className release];
    className = [newClassName retain];
}

- (NSArray *)protocols;
{
    return protocols;
}

- (void)setProtocols:(NSArray *)newProtocols;
{
    if (newProtocols == protocols)
        return;

    [protocols release];
    protocols = [newProtocols retain];
}

- (NSArray *)classMethods;
{
    return classMethods;
}

- (void)setClassMethods:(NSArray *)newClassMethods;
{
    if (newClassMethods == classMethods)
        return;

    [classMethods release];
    classMethods = [newClassMethods retain];
}

- (NSArray *)instanceMethods;
{
    return instanceMethods;
}

- (void)setInstanceMethods:(NSArray *)newInstanceMethods;
{
    if (newInstanceMethods == instanceMethods)
        return;

    [instanceMethods release];
    instanceMethods = [newInstanceMethods retain];
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] name: %@, className: %@", NSStringFromClass([self class]), name, className];
}

- (void)appendToString:(NSMutableString *)resultString;
{
    NSArray *sortedMethods;
    int count, index;

    [resultString appendFormat:@"@interface %@(%@)", className, name];

    if ([protocols count] > 0)
        [resultString appendFormat:@" <%@>", [[protocols arrayByMappingSelector:@selector(name)] componentsJoinedByString:@", "]];

    [resultString appendString:@"\n"];

    sortedMethods = [classMethods sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
    count = [sortedMethods count];
    if (count > 0) {
        for (index = 0; index < count; index++) {
            [resultString appendString:@"+ "];
            [[sortedMethods objectAtIndex:index] appendToString:resultString];
            [resultString appendString:@"\n"];
        }
    }

    sortedMethods = [instanceMethods sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
    count = [sortedMethods count];
    if (count > 0) {
        for (index = 0; index < count; index++) {
            [resultString appendString:@"- "];
            [[sortedMethods objectAtIndex:index] appendToString:resultString];
            [resultString appendString:@"\n"];
        }
    }

#if 0
    if ([classMethods count] > 0 || [instanceMethods count] > 0)
        [resultString appendString:@"\n"];
#endif
    [resultString appendString:@"@end\n\n"];
}

- (void)appendRawMethodsToString:(NSMutableString *)resultString;
{
    NSArray *sortedMethods;
    int count, index;

    [resultString appendFormat:@"\tCategory %@(%@)\n", className, name];
    sortedMethods = [classMethods sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
    count = [sortedMethods count];
    if (count > 0) {
        for (index = 0; index < count; index++) {
            CDOCMethod *aMethod;

            aMethod = [sortedMethods objectAtIndex:index];
            [resultString appendFormat:@"%@\t%@\n", [aMethod name], [aMethod type]];
        }
    }

    sortedMethods = [instanceMethods sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
    count = [sortedMethods count];
    if (count > 0) {
        for (index = 0; index < count; index++) {
            CDOCMethod *aMethod;

            aMethod = [sortedMethods objectAtIndex:index];
            [resultString appendFormat:@"%@\t%@\n", [aMethod name], [aMethod type]];
        }
    }
}

- (NSString *)sortableName;
{
    return [NSString stringWithFormat:@"%@ (%@)", className, name];
}

- (NSComparisonResult)ascendingCompareByName:(CDOCCategory *)otherCategory;
{
    // TODO (2003-12-12): Should use category name as second sort key
    return [[self sortableName] compare:[otherCategory sortableName]];
}

@end
