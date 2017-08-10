// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDOCProtocol.h"

#import "CDTopologicalSortProtocol.h"

@class CDOCClassReference;

@interface CDOCClass : CDOCProtocol <CDTopologicalSort>

@property (strong) CDOCClassReference *superClassRef;
@property (copy, readonly) NSString *superClassName;
@property (strong) NSArray *instanceVariables;
@property (assign) BOOL isExported;
@property (assign) BOOL isSwiftClass;

@end
