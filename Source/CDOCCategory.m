// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDOCCategory.h"

#import "CDClassDump.h"
#import "CDOCMethod.h"
#import "CDVisitor.h"
#import "CDVisitorPropertyState.h"
#import "CDOCClass.h"
#import "CDOCClassReference.h"

@implementation CDOCCategory

#pragma mark - Superclass overrides

- (NSString *)sortableName;
{
    return [NSString stringWithFormat:@"%@ (%@)", self.className, self.name];
}

#pragma mark -

- (NSString *)className
{
    return [_classRef className];
}

- (NSString *)methodSearchContext;
{
    NSMutableString *resultString = [NSMutableString string];

    [resultString appendFormat:@"@interface %@ (%@)", self.className, self.name];

    if ([self.protocols count] > 0)
        [resultString appendFormat:@" <%@>", self.protocolsString];

    return resultString;
}

- (void)recursivelyVisit:(CDVisitor *)visitor;
{
    if ([visitor.classDump shouldShowName:self.name]) {
        CDVisitorPropertyState *propertyState = [[CDVisitorPropertyState alloc] initWithProperties:self.properties];
        
        [visitor willVisitCategory:self];
        
        //[aVisitor willVisitPropertiesOfCategory:self];
        //[self visitProperties:aVisitor];
        //[aVisitor didVisitPropertiesOfCategory:self];
        
        [self visitMethods:visitor propertyState:propertyState];
        // This can happen when... the accessors are implemented on the main class.  Odd case, but we should still emit the remaining properties.
        // Should mostly be dynamic properties
        [visitor visitRemainingProperties:propertyState];
        [visitor didVisitCategory:self];
    }
}

#pragma mark - CDTopologicalSort protocol

- (NSString *)identifier;
{
    return self.sortableName;
}

- (NSArray *)dependancies;
{
    if (self.className == nil)
        return @[];

    return @[self.className];
}

@end
