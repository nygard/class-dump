//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import "CDOCCategory.h"

#import "rcsid.h"
#import <Foundation/Foundation.h>
#import "CDClassDump.h"
#import "CDOCMethod.h"
#import "CDSymbolReferences.h"
#import "NSArray-Extensions.h"

RCS_ID("$Header: /Volumes/Data/tmp/Tools/class-dump/CDOCCategory.m,v 1.8 2004/02/02 23:21:21 nygard Exp $");

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

- (void)appendToString:(NSMutableString *)resultString classDump:(CDClassDump2 *)aClassDump symbolReferences:(CDSymbolReferences *)symbolReferences;
{
    [resultString appendFormat:@"@interface %@(%@)", className, name];

    if ([protocols count] > 0) {
        [resultString appendFormat:@" <%@>", [[protocols arrayByMappingSelector:@selector(name)] componentsJoinedByString:@", "]];
        [symbolReferences addProtocolNamesFromArray:[protocols arrayByMappingSelector:@selector(name)]];
    }

    [resultString appendString:@"\n"];
    [self appendMethodsToString:resultString classDump:aClassDump symbolReferences:symbolReferences];
    [resultString appendString:@"@end\n\n"];
}

- (NSString *)sortableName;
{
    return [NSString stringWithFormat:@"%@ (%@)", className, name];
}

@end
