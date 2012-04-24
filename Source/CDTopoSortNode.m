// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDTopoSortNode.h"

@implementation CDTopoSortNode
{
    id <CDTopologicalSort> sortableObject;
    
    NSMutableSet *dependancies;
    CDNodeColor color;
}

- (id)initWithObject:(id <CDTopologicalSort>)object;
{
    if ((self = [super init])) {
        sortableObject = object;
        dependancies = [[NSMutableSet alloc] init];
        color = CDNodeColor_White;

        [self addDependanciesFromArray:[sortableObject dependancies]];
    }

    return self;
}

#pragma mark -

- (NSString *)identifier;
{
    return [sortableObject identifier];
}

@synthesize sortableObject;

- (NSArray *)dependancies;
{
    return [dependancies allObjects];
}

- (void)addDependancy:(NSString *)identifier;
{
    [dependancies addObject:identifier];
}

- (void)removeDependancy:(NSString *)identifier;
{
    [dependancies removeObject:identifier];
}

- (void)addDependanciesFromArray:(NSArray *)identifiers;
{
    [dependancies addObjectsFromArray:identifiers];
}

- (NSString *)dependancyDescription;
{
    return [[dependancies allObjects] componentsJoinedByString:@", "];
}

@synthesize color;

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"%@ (%lu) depends on %@", self.identifier, self.color, self.dependancyDescription];
}

#pragma mark - Sorting

- (NSComparisonResult)ascendingCompareByIdentifier:(CDTopoSortNode *)otherNode;
{
    return [self.identifier compare:otherNode.identifier];
}

- (void)topologicallySortNodes:(NSDictionary *)nodesByIdentifier intoArray:(NSMutableArray *)sortedArray;
{
    NSArray *dependantIdentifiers = [self dependancies];

    for (NSString *identifier in dependantIdentifiers) {
        CDTopoSortNode *node = [nodesByIdentifier objectForKey:identifier];
        if ([node color] == CDNodeColor_White) {
            [node setColor:CDNodeColor_Gray];
            [node topologicallySortNodes:nodesByIdentifier intoArray:sortedArray];
        } else if ([node color] == CDNodeColor_Gray) {
            NSLog(@"Warning: Possible circular reference? %@ -> %@", self.identifier, node.identifier);
        }
    }

    [sortedArray addObject:[self sortableObject]];
    self.color = CDNodeColor_Black;
}

@end
