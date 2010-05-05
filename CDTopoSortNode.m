// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDTopoSortNode.h"

#import "NSObject-CDExtensions.h"

@implementation CDTopoSortNode

- (id)initWithObject:(id <CDTopologicalSort>)anObject;
{
    if ([super init] == nil)
        return nil;

    sortableObject = [anObject retain];
    dependancies = [[NSMutableSet alloc] init];
    color = CDWhiteNodeColor;

    [self addDependanciesFromArray:[sortableObject dependancies]];

    return self;
}

- (void)dealloc;
{
    [sortableObject release];
    [dependancies release];

    [super dealloc];
}

- (NSString *)identifier;
{
    return [sortableObject identifier];
}

- (id <CDTopologicalSort>)sortableObject;
{
    return sortableObject;
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

- (CDNodeColor)color;
{
    return color;
}

- (void)setColor:(CDNodeColor)newColor;
{
    color = newColor;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"%@ (%d) depends on %@", [self identifier], color, [[dependancies allObjects] componentsJoinedByString:@", "]];
}

- (NSComparisonResult)ascendingCompareByIdentifier:(id)otherNode;
{
    return [[self identifier] compare:[otherNode identifier]];
}

- (void)topologicallySortNodes:(NSDictionary *)nodesByIdentifier intoArray:(NSMutableArray *)sortedArray;
{
    NSArray *dependantIdentifiers;
    CDTopoSortNode *aNode;

    dependantIdentifiers = [self dependancies];
    for (NSString *anIdentifier in dependantIdentifiers) {
        aNode = [nodesByIdentifier objectForKey:anIdentifier];
        if ([aNode color] == CDWhiteNodeColor) {
            [aNode setColor:CDGrayNodeColor];
            [aNode topologicallySortNodes:nodesByIdentifier intoArray:sortedArray];
        } else if ([aNode color] == CDGrayNodeColor) {
            NSLog(@"Warning: Possible circular reference? %@ -> %@", [self identifier], [aNode identifier]);
        }
    }

    [sortedArray addObject:[self sortableObject]];
    [self setColor:CDBlackNodeColor];
}

@end
