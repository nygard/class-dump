//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import "CDOCCategory.h"

#import "rcsid.h"
#import <Foundation/Foundation.h>
#import "CDClassDump.h"
#import "CDOCMethod.h"
#import "NSArray-Extensions.h"

RCS_ID("$Header: /Volumes/Data/tmp/Tools/class-dump/CDOCCategory.m,v 1.7 2004/01/15 23:30:40 nygard Exp $");

@implementation CDOCCategory

- (void)dealloc;
{
    [className release];

    [super dealloc];
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

- (void)appendToString:(NSMutableString *)resultString classDump:(CDClassDump2 *)aClassDump;
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
            [[sortedMethods objectAtIndex:index] appendToString:resultString classDump:aClassDump];
            [resultString appendString:@"\n"];
        }
    }

    sortedMethods = [instanceMethods sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
    count = [sortedMethods count];
    if (count > 0) {
        for (index = 0; index < count; index++) {
            [resultString appendString:@"- "];
            [[sortedMethods objectAtIndex:index] appendToString:resultString classDump:aClassDump];
            [resultString appendString:@"\n"];
        }
    }

    [resultString appendString:@"@end\n\n"];
}

- (NSString *)sortableName;
{
    return [NSString stringWithFormat:@"%@ (%@)", className, name];
}

@end
