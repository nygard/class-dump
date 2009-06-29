// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import <Foundation/Foundation.h>

@interface CDOCProperty : NSObject
{
    NSString *name;
    NSString *attributes;
}

- (id)initWithName:(NSString *)aName attributes:(NSString *)someAttributes;
- (void)dealloc;

- (NSString *)name;
- (NSString *)attributes;

- (NSString *)description;

- (NSComparisonResult)ascendingCompareByName:(CDOCProperty *)otherProperty;

@end
