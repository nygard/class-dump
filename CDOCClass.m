// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDOCClass.h"

#import "NSArray-Extensions.h"
#import "CDClassDump.h"
#import "CDOCIvar.h"
#import "CDOCMethod.h"
#import "CDSymbolReferences.h"
#import "CDType.h"
#import "CDTypeController.h"
#import "CDTypeParser.h"
#import "CDVisitor.h"
#import "CDVisitorPropertyState.h"

@implementation CDOCClass

- (id)init;
{
    if ([super init] == nil)
        return nil;

    superClassName = nil;
    ivars = nil;

    isExported = YES;

    return self;
}

- (void)dealloc;
{
    [superClassName release];
    [ivars release];

    [super dealloc];
}

- (NSString *)superClassName;
{
    return superClassName;
}

- (void)setSuperClassName:(NSString *)newSuperClassName;
{
    if (newSuperClassName == superClassName)
        return;

    [superClassName release];
    superClassName = [newSuperClassName retain];
}

- (NSArray *)ivars;
{
    return ivars;
}

- (void)setIvars:(NSArray *)newIvars;
{
    if (newIvars == ivars)
        return;

    [ivars release];
    ivars = [newIvars retain];
}

@synthesize isExported;

- (NSString *)description;
{
    return [NSString stringWithFormat:@"%@, exported: %@", [super description], isExported ? @"YES" : @"NO"];
}

- (void)registerTypesWithObject:(CDTypeController *)typeController phase:(NSUInteger)phase;
{
    [super registerTypesWithObject:typeController phase:phase];

    for (CDOCIvar *ivar in ivars) {
        [[ivar parsedType] phase:phase registerTypesWithObject:typeController usedInMethod:NO];
    }
}

- (NSString *)findTag:(CDSymbolReferences *)symbolReferences;
{
    NSMutableString *resultString = [NSMutableString string];

    [resultString appendFormat:@"@interface %@", name];
    if (superClassName != nil)
        [resultString appendFormat:@" : %@", superClassName];

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

    [aVisitor willVisitClass:self];

    [aVisitor willVisitIvarsOfClass:self];
    for (CDOCIvar *ivar in ivars)
        [aVisitor visitIvar:ivar];
    [aVisitor didVisitIvarsOfClass:self];

    //[aVisitor willVisitPropertiesOfClass:self];
    //[self visitProperties:aVisitor];
    //[aVisitor didVisitPropertiesOfClass:self];

    [self visitMethods:aVisitor propertyState:propertyState];
    // Should mostly be dynamic properties
    [aVisitor visitRemainingProperties:propertyState];
    [aVisitor didVisitClass:self];

    [propertyState release];
}

//
// CDTopologicalSort protocol
//

- (NSString *)identifier;
{
    return [self name];
}

- (NSArray *)dependancies;
{
    if (superClassName == nil)
        return [NSArray array];

    return [NSArray arrayWithObject:superClassName];
}

@end
