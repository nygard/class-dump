// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "NSArray-CDExtensions.h"

@implementation NSArray (CDExtensions)

- (NSArray *)reversedArray;
{
    return [[self reverseObjectEnumerator] allObjects];
}

@end

#pragma mark -

@implementation NSArray (CDTopoSort)

- (NSArray *)topologicallySortedArray;
{
    NSMutableDictionary *nodesByName = [[NSMutableDictionary alloc] init];

    for (id <CDTopologicalSort> object in self) {
        CDTopoSortNode *node = [[CDTopoSortNode alloc] initWithObject:object];
        [node addDependanciesFromArray:[object dependancies]];

        if (nodesByName[node.identifier] != nil)
            NSLog(@"Warning: Duplicate identifier (%@) in %s", node.identifier, __cmd);
        nodesByName[node.identifier] = node;
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
