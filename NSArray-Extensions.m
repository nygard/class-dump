//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import "NSArray-Extensions.h"

#import "rcsid.h"
#import <Foundation/Foundation.h>
#import "CDTopoSortNode.h"

RCS_ID("$Header: /Volumes/Data/tmp/Tools/class-dump/NSArray-Extensions.m,v 1.8 2004/02/11 01:35:22 nygard Exp $");

@implementation NSArray (CDExtensions)

- (NSArray *)reversedArray;
{
    return [[self reverseObjectEnumerator] allObjects];
}

- (NSArray *)arrayByMappingSelector:(SEL)aSelector;
{
    NSMutableArray *newArray;
    int count, index;
    id value;

    newArray = [NSMutableArray array];
    count = [self count];
    for (index = 0; index < count; index++) {
        value = [[self objectAtIndex:index] performSelector:aSelector];
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
    NSMutableDictionary *nodesByName;
    int count, index;
    id <CDTopologicalSort> anObject;

    NSMutableArray *sortedArray;
    NSArray *allNodes;

    nodesByName = [[NSMutableDictionary alloc] init];

    count = [self count];
    for (index = 0; index < count; index++) {
        NSString *identifier;
        CDTopoSortNode *aNode;

        anObject = [self objectAtIndex:index];

        aNode = [[CDTopoSortNode alloc] initWithObject:anObject];
        [aNode addDependanciesFromArray:[anObject dependancies]];

        identifier = [aNode identifier];
        if ([nodesByName objectForKey:identifier] != nil)
            NSLog(@"Warning: Duplicate identifier (%@) in %s", identifier, _cmd);
        [nodesByName setObject:aNode forKey:identifier];
        [aNode release];
    }

    sortedArray = [NSMutableArray array];

    allNodes = [[nodesByName allValues] sortedArrayUsingSelector:@selector(ascendingCompareByIdentifier:)];
    count = [allNodes count];
    for (index = 0; index < count; index++) {
        CDTopoSortNode *aNode;

        aNode = [allNodes objectAtIndex:index];
        if ([aNode color] == CDWhiteNodeColor)
            [aNode topologicallySortNodes:nodesByName intoArray:sortedArray];
    }

    [nodesByName release];

    return sortedArray;
}

@end


@implementation NSMutableArray (CDTopoSort)

- (void)sortTopologically;
{
    NSArray *sortedArray;

    sortedArray = [self topologicallySortedArray];
    assert([self count] == [sortedArray count]);

    [self removeAllObjects];
    [self addObjectsFromArray:sortedArray];
}

@end
