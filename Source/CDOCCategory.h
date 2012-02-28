// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDOCProtocol.h"

@interface CDOCCategory : CDOCProtocol <CDTopologicalSort>

@property (strong) NSString *className;

- (NSString *)methodSearchContext;
- (void)recursivelyVisit:(CDVisitor *)visitor;

@end
