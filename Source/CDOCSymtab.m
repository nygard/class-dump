// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDOCSymtab.h"

#import "CDOCCategory.h"
#import "CDOCClass.h"

@implementation CDOCSymtab
{
    NSMutableArray *classes;
    NSMutableArray *categories;
}

- (id)init;
{
    if ((self = [super init])) {
        classes = [[NSMutableArray alloc] init];
        categories = [[NSMutableArray alloc] init];
    }

    return self;
}

- (void)dealloc;
{
    [classes release];
    [categories release];

    [super dealloc];
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] classes: %@, categories: %@", NSStringFromClass([self class]), self.classes, self.categories];
}

#pragma mark -

@synthesize classes;

- (void)addClass:(CDOCClass *)aClass;
{
    [self.classes addObject:aClass];
}

@synthesize categories;

- (void)addCategory:(CDOCCategory *)aCategory;
{
    [self.categories addObject:aCategory];
}

@end
