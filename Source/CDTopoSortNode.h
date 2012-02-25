// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import <Foundation/Foundation.h>
#import "CDTopologicalSortProtocol.h"

enum {
    CDNodeColor_White = 0,
    CDNodeColor_Gray  = 1,
    CDNodeColor_Black = 2,
};
typedef NSUInteger CDNodeColor;

@interface CDTopoSortNode : NSObject

- (id)initWithObject:(id <CDTopologicalSort>)object;

@property (readonly) NSString *identifier;
@property (readonly) id <CDTopologicalSort> sortableObject;

- (NSArray *)dependancies;
- (void)addDependancy:(NSString *)identifier;
- (void)removeDependancy:(NSString *)identifier;
- (void)addDependanciesFromArray:(NSArray *)identifiers;
@property (readonly) NSString *dependancyDescription;

@property (assign) CDNodeColor color;

- (NSString *)description;

- (NSComparisonResult)ascendingCompareByIdentifier:(CDTopoSortNode *)otherNode;
- (void)topologicallySortNodes:(NSDictionary *)nodesByIdentifier intoArray:(NSMutableArray *)sortedArray;

@end
