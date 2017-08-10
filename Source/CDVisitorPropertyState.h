// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

@class CDOCProperty;

@interface CDVisitorPropertyState : NSObject

- (id)initWithProperties:(NSArray *)properties;

- (CDOCProperty *)propertyForAccessor:(NSString *)str;

- (BOOL)hasUsedProperty:(CDOCProperty *)property;
- (void)useProperty:(CDOCProperty *)property;

@property (nonatomic, readonly) NSArray *remainingProperties;

@end
