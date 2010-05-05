// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDOCCategory.h"

#import "CDClassDump.h"
#import "CDOCMethod.h"
#import "CDSymbolReferences.h"
#import "NSArray-Extensions.h"
#import "CDVisitor.h"
#import "CDVisitorPropertyState.h"

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
    CDVisitorPropertyState *propertyState;

    if ([[aVisitor classDump] shouldMatchRegex] && [[aVisitor classDump] regexMatchesString:[self name]] == NO)
        return;

    // Wonderful.  Need to typecast because there's also -[NSHTTPCookie initWithProperties:] that takes a dictionary.
    propertyState = [(CDVisitorPropertyState *)[CDVisitorPropertyState alloc] initWithProperties:[self properties]];

    [aVisitor willVisitCategory:self];

    //[aVisitor willVisitPropertiesOfCategory:self];
    //[self visitProperties:aVisitor];
    //[aVisitor didVisitPropertiesOfCategory:self];

    [self visitMethods:aVisitor propertyState:propertyState];
    // This can happen when... the accessors are implemented on the main class.  Odd case, but we should still emit the remaining properties.
    // Should mostly be dynamic properties
    [aVisitor visitRemainingProperties:propertyState];
    [aVisitor didVisitCategory:self];

    [propertyState release];
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
