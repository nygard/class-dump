// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2011 Steve Nygard.

#import <Foundation/Foundation.h>
#import "CDTopologicalSortProtocol.h"

enum {
    CDNodeColor_White = 0,
    CDNodeColor_Gray = 1,
    CDNodeColor_Black = 2,
};
typedef NSUInteger CDNodeColor;

@interface CDTopoSortNode : NSObject
{
    id <CDTopologicalSort> sortableObject;

    NSMutableSet *dependancies;
    CDNodeColor color;
}

- (id)initWithObject:(id <CDTopologicalSort>)anObject;
- (void)dealloc;

- (NSString *)identifier;
- (id <CDTopologicalSort>)sortableObject;

- (NSArray *)dependancies;
- (void)addDependancy:(NSString *)anIdentifier;
- (void)removeDependancy:(NSString *)anIdentifier;
- (void)addDependanciesFromArray:(NSArray *)identifiers;

- (CDNodeColor)color;
- (void)setColor:(CDNodeColor)newColor;

- (NSString *)description;

- (NSComparisonResult)ascendingCompareByIdentifier:(id)otherNode;
- (void)topologicallySortNodes:(NSDictionary *)nodesByIdentifier intoArray:(NSMutableArray *)sortedArray;

@end
