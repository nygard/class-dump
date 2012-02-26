// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDTypeController;

@interface CDOCMethod : NSObject <NSCopying>

- (id)initWithName:(NSString *)name type:(NSString *)type imp:(NSUInteger)imp;
- (id)initWithName:(NSString *)name type:(NSString *)type;

@property (readonly) NSString *name;
@property (readonly) NSString *type;
@property (assign) NSUInteger imp;

- (NSArray *)parsedMethodTypes;

- (void)appendToString:(NSMutableString *)resultString typeController:(CDTypeController *)typeController;

- (NSComparisonResult)ascendingCompareByName:(CDOCMethod *)otherMethod;

@end
