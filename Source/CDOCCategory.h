// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2014 Steve Nygard.

#import "CDOCProtocol.h"

@class CDOCClassReference;

@interface CDOCCategory : CDOCProtocol <CDTopologicalSort>

@property (strong) CDOCClassReference *classRef;
@property (strong, readonly) NSString *className;
@property (assign) uint64_t address;

- (NSString *)methodSearchContext;
- (void)recursivelyVisit:(CDVisitor *)visitor;

@end
