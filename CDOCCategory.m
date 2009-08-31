// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import "CDOCCategory.h"

#import "CDClassDump.h"
#import "CDOCMethod.h"
#import "CDSymbolReferences.h"
#import "NSArray-Extensions.h"
#import "CDVisitor.h"

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

- (NSString *)sortableName;
{
    return [NSString stringWithFormat:@"%@ (%@)", className, name];
}

- (NSString *)findTag:(CDSymbolReferences *)symbolReferences;
{
    NSMutableString *resultString = [NSMutableString string];

    [resultString appendFormat:@"@interface %@ (%@)", className, name];

    if ([protocols count] > 0)
        [resultString appendFormat:@" <%@>", [[protocols arrayByMappingSelector:@selector(name)] componentsJoinedByString:@", "]];

    return resultString;
}

- (void)recursivelyVisit:(CDVisitor *)aVisitor;
{
    if ([[aVisitor classDump] shouldMatchRegex] && [[aVisitor classDump] regexMatchesString:[self name]] == NO)
        return;

    [aVisitor willVisitCategory:self];

    [aVisitor willVisitPropertiesOfCategory:self];
    [self visitProperties:aVisitor];
    [aVisitor didVisitPropertiesOfCategory:self];

    [self recursivelyVisitMethods:aVisitor];
    [aVisitor didVisitCategory:self];
}

//
// CDTopologicalSort protocol
//

- (NSString *)identifier;
{
    return [self sortableName];
}

- (NSArray *)dependancies;
{
    if (className == nil)
        return [NSArray array];

    return [NSArray arrayWithObject:className];
}

@end
