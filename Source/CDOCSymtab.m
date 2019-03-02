// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "CDOCSymtab.h"

#import "CDOCCategory.h"
#import "CDOCClass.h"

@implementation CDOCSymtab
{
    NSMutableArray *_classes;
    NSMutableArray *_categories;
}

- (id)init;
{
    if ((self = [super init])) {
        _classes = [[NSMutableArray alloc] init];
        _categories = [[NSMutableArray alloc] init];
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] classes: %@, categories: %@", NSStringFromClass([self class]), self.classes, self.categories];
}

#pragma mark -

- (void)addClass:(CDOCClass *)aClass;
{
    [self.classes addObject:aClass];
}

- (void)addCategory:(CDOCCategory *)category;
{
    [self.categories addObject:category];
}

@end
