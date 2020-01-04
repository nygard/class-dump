// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

@class CDOCCategory, CDOCClass;

@interface CDOCSymtab : NSObject

@property (readonly) NSMutableArray *classes;
- (void)addClass:(CDOCClass *)aClass;

@property (readonly) NSMutableArray *categories;
- (void)addCategory:(CDOCCategory *)category;

@end
