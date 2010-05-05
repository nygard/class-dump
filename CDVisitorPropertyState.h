// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDOCProperty;

@interface CDVisitorPropertyState : NSObject
{
    NSMutableDictionary *propertiesByAccessor; // key: NSString (accessor), value: CDOCProperty
    NSMutableDictionary *propertiesByName; // key: NSString (property name), value: CDOCProperty
}

- (id)initWithProperties:(NSArray *)properties;
- (void)dealloc;

- (CDOCProperty *)propertyForAccessor:(NSString *)str;

- (BOOL)hasUsedProperty:(CDOCProperty *)property;
- (void)useProperty:(CDOCProperty *)property;

- (NSArray *)remainingProperties;

- (void)log;

@end
