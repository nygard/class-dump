// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDSearchPathState.h"

@implementation CDSearchPathState
{
    NSString *executablePath;
    NSMutableArray *searchPathStack;
}

- (id)init;
{
    if ((self = [super init])) {
        executablePath = nil;
        searchPathStack = [[NSMutableArray alloc] init];
    }

    return self;
}

- (void)dealloc;
{
    [executablePath release];
    [searchPathStack release];

    [super dealloc];
}

#pragma mark -

@synthesize executablePath;

- (void)pushSearchPaths:(NSArray *)searchPaths;
{
    [searchPathStack addObject:searchPaths];
}

- (void)popSearchPaths;
{
    if ([searchPathStack count] > 0) {
        [searchPathStack removeLastObject];
    } else {
        NSLog(@"Warning: Unbalanced popSearchPaths");
    }

}

- (NSString *)resolvePath:(NSString *)aPath;
{
    for (NSArray *group in searchPathStack) {
        for (NSString *path in group) {
            NSLog(@"path %@", path);
        }
    }

    return aPath;
}

- (NSArray *)searchPaths;
{
    NSMutableArray *result = [NSMutableArray array];
    for (NSArray *group in searchPathStack) {
        [result addObjectsFromArray:group];
    }

    return [NSArray arrayWithArray:result];
    //return [[result copy] autorelease];
}

@end
