// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDOCProtocol.h"
#import "CDTopologicalSortProtocol.h"

@interface CDOCClass : CDOCProtocol <CDTopologicalSort>

@property (retain) NSString *superClassName;
@property (retain) NSArray *ivars;
@property (assign) BOOL isExported;

- (void)registerTypesWithObject:(CDTypeController *)typeController phase:(NSUInteger)phase;

- (NSString *)findTag:(CDSymbolReferences *)symbolReferences;
- (void)recursivelyVisit:(CDVisitor *)aVisitor;

@end
