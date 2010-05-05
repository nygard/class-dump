// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDOCSymtab.h"

#import "CDClassDump.h"
#import "CDOCCategory.h"
#import "CDOCClass.h"
#import "CDSymbolReferences.h"

@implementation CDOCSymtab

- (id)init;
{
    if ([super init] == nil)
        return nil;

    classes = [[NSMutableArray alloc] init];
    categories = [[NSMutableArray alloc] init];

    return self;
}

- (void)dealloc;
{
    [classes release];
    [categories release];

    [super dealloc];
}

- (NSArray *)classes;
{
    return classes;
}

- (void)addClass:(CDOCClass *)aClass;
{
    [classes addObject:aClass];
}

- (NSArray *)categories;
{
    return categories;
}

- (void)addCategory:(CDOCCategory *)aCategory;
{
    [categories addObject:aCategory];
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] classes: %@, categories: %@", NSStringFromClass([self class]), classes, categories];
}

@end
