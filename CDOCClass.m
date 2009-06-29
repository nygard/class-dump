// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import "CDOCClass.h"

#import <Foundation/Foundation.h>
#import "NSArray-Extensions.h"
#import "CDClassDump.h"
#import "CDOCIvar.h"
#import "CDOCMethod.h"
#import "CDSymbolReferences.h"
#import "CDType.h"
#import "CDTypeParser.h"
#import "CDVisitor.h"

@implementation CDOCClass

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

- (void)registerStructuresWithObject:(id <CDStructureRegistration>)anObject phase:(int)phase;
{
    CDTypeParser *parser;

    [super registerStructuresWithObject:anObject phase:phase];

    for (CDOCIvar *ivar in ivars) {
        CDType *aType;
        NSError *error;

        parser = [[CDTypeParser alloc] initWithType:[ivar type]];
        aType = [parser parseType:&error];
        [aType phase:phase registerStructuresWithObject:anObject usedInMethod:NO];
        [parser release];
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
    if ([[aVisitor classDump] shouldMatchRegex] && [[aVisitor classDump] regexMatchesString:[self name]] == NO)
        return;

    [aVisitor willVisitClass:self];

    [aVisitor willVisitIvarsOfClass:self];
    for (CDOCIvar *ivar in ivars)
        [aVisitor visitIvar:ivar];
    [aVisitor didVisitIvarsOfClass:self];

    [aVisitor willVisitPropertiesOfClass:self];
    [self visitProperties:aVisitor];
    [aVisitor didVisitPropertiesOfClass:self];

    [self recursivelyVisitMethods:aVisitor];
    [aVisitor didVisitClass:self];
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
