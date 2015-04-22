// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDTopoSortNode.h"

@implementation CDTopoSortNode
{
    id <CDTopologicalSort> _sortableObject;
    
    NSMutableSet *_dependancies;
    CDNodeColor _color;
}

- (id)initWithObject:(id <CDTopologicalSort>)object;
{
    if ((self = [super init])) {
        _sortableObject = object;
        _dependancies = [[NSMutableSet alloc] init];
        _color = CDNodeColor_White;

        [self addDependanciesFromArray:[_sortableObject dependancies]];
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"%@ (%lu) depends on %@", self.identifier, self.color, self.dependancyDescription];
}

#pragma mark -

- (NSString *)identifier;
{
    return self.sortableObject.identifier;
}

- (NSArray *)dependancies;
{
    return [_dependancies allObjects];
}

- (void)addDependancy:(NSString *)identifier;
{
    [_dependancies addObject:identifier];
}

- (void)removeDependancy:(NSString *)identifier;
{
    [_dependancies removeObject:identifier];
}

- (void)addDependanciesFromArray:(NSArray *)identifiers;
{
    [_dependancies addObjectsFromArray:identifiers];
}

- (NSString *)dependancyDescription;
{
    return [[_dependancies allObjects] componentsJoinedByString:@", "];
}

#pragma mark - Sorting

- (NSComparisonResult)ascendingCompareByIdentifier:(CDTopoSortNode *)other;
{
    return [self.identifier compare:other.identifier];
}

- (void)topologicallySortNodes:(NSDictionary *)nodesByIdentifier intoArray:(NSMutableArray *)sortedArray;
{
    NSArray *dependantIdentifiers = [self dependancies];

    for (NSString *identifier in dependantIdentifiers) {
        CDTopoSortNode *node = nodesByIdentifier[identifier];
        if (node.color == CDNodeColor_White) {
            node.color = CDNodeColor_Gray;
            [node topologicallySortNodes:nodesByIdentifier intoArray:sortedArray];
        } else if (node.color == CDNodeColor_Gray) {
            NSLog(@"Warning: Possible circular reference? %@ -> %@", self.identifier, node.identifier);
        }
    }

    [sortedArray addObject:[self sortableObject]];
    self.color = CDNodeColor_Black;
}

@end
