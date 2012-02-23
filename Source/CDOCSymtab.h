// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDClassDump;
@class CDOCCategory, CDOCClass;

@interface CDOCSymtab : NSObject

- (NSString *)description;

@property (readonly) NSMutableArray *classes;
- (void)addClass:(CDOCClass *)aClass;

@property (readonly) NSMutableArray *categories;
- (void)addCategory:(CDOCCategory *)aCategory;

@end
