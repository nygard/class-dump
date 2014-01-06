// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2013 Steve Nygard.

#import "CDOCProtocol.h"

@interface CDOCCategory : CDOCProtocol <CDTopologicalSort>

@property (strong) id classRef; // Can be CDOCClass, CDSymbol (for external classes), or NSString (for ObjC1 class refs)
@property (strong, readonly) NSString *className;

- (NSString *)methodSearchContext;
- (void)recursivelyVisit:(CDVisitor *)visitor;

@end
