// This file is part of APPNAME, SHORT DESCRIPTION
// Copyright (C) 2003 Steve Nygard.  All rights reserved.

#import "CDTopoSortNode.h"

#import <Foundation/Foundation.h>
#import "NSObject-CDExtensions.h"

@implementation CDTopoSortNode

- (id)initWithIdentifier:(NSString *)anIdentifier;
{
    if ([super init] == nil)
        return nil;

    identifier = [anIdentifier retain];
    dependancies = [[NSMutableSet alloc] init];

    return self;
}

- (void)dealloc;
{
    [identifier release];
    [dependancies release];

    [super dealloc];
}

- (NSString *)identifier;
{
    return identifier;
}

- (NSArray *)dependancies;
{
    return [dependancies allObjects];
}

- (void)addDependancy:(NSString *)anIdentifier;
{
    [dependancies addObject:anIdentifier];
}

- (void)removeDependancy:(NSString *)anIdentifier;
{
    [dependancies removeObject:anIdentifier];
}

- (void)addDependanciesFromArray:(NSArray *)identifiers;
{
    [self performSelector:@selector(addDependancy:) withObjectsFromArray:identifiers];
    //[identifiers makeObject:self performSelector:@selector(addDependancy:)];
}

@end
