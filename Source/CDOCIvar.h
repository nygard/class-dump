// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDType, CDTypeController;

@interface CDOCIvar : NSObject

- (id)initWithName:(NSString *)name type:(NSString *)type offset:(NSUInteger)offset;

@property (readonly) NSString *name;
@property (readonly) NSString *type;
@property (readonly) NSUInteger offset;

@property (nonatomic, readonly) CDType *parsedType;

- (void)appendToString:(NSMutableString *)resultString typeController:(CDTypeController *)typeController;

@end
