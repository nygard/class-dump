// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "NSArray-Extensions.h"

#import "CDTopoSortNode.h"

@implementation NSArray (CDExtensions)

- (NSArray *)reversedArray;
{
    return [[self reverseObjectEnumerator] allObjects];
}

- (NSArray *)arrayByMappingSelector:(SEL)aSelector;
{
    NSMutableArray *newArray;

    newArray = [NSMutableArray array];
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
    NSMutableDictionary *nodesByName;
    NSMutableArray *sortedArray;
    NSArray *allNodes;

    nodesByName = [[NSMutableDictionary alloc] init];

    for (id <CDTopologicalSort> anObject in self) {
        NSString *identifier;
        CDTopoSortNode *aNode;

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
    for (CDTopoSortNode *aNode in allNodes) {
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
