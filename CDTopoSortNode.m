//
// $Id: CDTopoSortNode.m,v 1.2 2004/01/06 01:51:56 nygard Exp $
//

//  This file is part of class-dump, a utility for exmaing the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

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
