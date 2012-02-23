// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDOCClass.h"

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
{
    NSString *superClassName;
    NSArray *ivars;
    
    BOOL isExported;
}

- (id)init;
{
    if ((self = [super init])) {
        superClassName = nil;
        ivars = nil;
        
        isExported = YES;
    }

    return self;
}

- (void)dealloc;
{
    [superClassName release];
    [ivars release];

    [super dealloc];
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"%@, exported: %@", [super description], self.isExported ? @"YES" : @"NO"];
}

#pragma mark -

@synthesize superClassName;
@synthesize ivars;
@synthesize isExported;

- (void)registerTypesWithObject:(CDTypeController *)typeController phase:(NSUInteger)phase;
{
    [super registerTypesWithObject:typeController phase:phase];

    for (CDOCIvar *ivar in self.ivars) {
        [[ivar parsedType] phase:phase registerTypesWithObject:typeController usedInMethod:NO];
    }
}

- (NSString *)findTag:(CDSymbolReferences *)symbolReferences;
{
    NSMutableString *resultString = [NSMutableString string];

    [resultString appendFormat:@"@interface %@", self.name];
    if (self.superClassName != nil)
        [resultString appendFormat:@" : %@", self.superClassName];

    if ([self.protocols count] > 0)
        [resultString appendFormat:@" <%@>", [[self.protocols arrayByMappingSelector:@selector(name)] componentsJoinedByString:@", "]];

    return resultString;
}

- (void)recursivelyVisit:(CDVisitor *)aVisitor;
{
    if ([[aVisitor classDump] shouldMatchRegex] && [[aVisitor classDump] regexMatchesString:[self name]] == NO)
        return;

    // Wonderful.  Need to typecast because there's also -[NSHTTPCookie initWithProperties:] that takes a dictionary.
    CDVisitorPropertyState *propertyState = [(CDVisitorPropertyState *)[CDVisitorPropertyState alloc] initWithProperties:[self properties]];

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

#pragma mark - CDTopologicalSort protocol

- (NSString *)identifier;
{
    return self.name;
}

- (NSArray *)dependancies;
{
    if (self.superClassName == nil)
        return [NSArray array];

    return [NSArray arrayWithObject:self.superClassName];
}

@end
