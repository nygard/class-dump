// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "NSArray-CDExtensions.h"

@implementation NSArray (CDExtensions)

- (NSArray *)reversedArray;
{
    return [[self reverseObjectEnumerator] allObjects];
}

- (NSArray *)arrayByMappingSelector:(SEL)aSelector;
{
    NSMutableArray *newArray = [NSMutableArray array];
    for (id object in self) {
        id value = [object performSelector:aSelector];
        if (value != nil)
            [newArray addObject:value];
        // TODO (2004-01-28): Or we could add NSNull.
    }

    return newArray;
}

@end

@implementation NSArray (CDTopoSort)

- (NSArray *)topologicallySortedArray;
{
    NSMutableDictionary *nodesByName = [[NSMutableDictionary alloc] init];

    for (id <CDTopologicalSort> anObject in self) {
        CDTopoSortNode *node = [[CDTopoSortNode alloc] initWithObject:anObject];
        [node addDependanciesFromArray:[anObject dependancies]];

        if ([nodesByName objectForKey:node.identifier] != nil)
            NSLog(@"Warning: Duplicate identifier (%@) in %s", node.identifier, __cmd);
        [nodesByName setObject:node forKey:node.identifier];
    }

    NSMutableArray *sortedArray = [NSMutableArray array];

    NSArray *allNodes = [[nodesByName allValues] sortedArrayUsingSelector:@selector(ascendingCompareByIdentifier:)];
    for (CDTopoSortNode *node in allNodes) {
        if (node.color == CDNodeColor_White)
            [node topologicallySortNodes:nodesByName intoArray:sortedArray];
    }


    return sortedArray;
}

@end

#pragma mark -

@implementation NSMutableArray (CDTopoSort)

- (void)sortTopologically;
{
    NSArray *sortedArray = [self topologicallySortedArray];
    assert([self count] == [sortedArray count]);

    [self removeAllObjects];
    [self addObjectsFromArray:sortedArray];
}

@end
