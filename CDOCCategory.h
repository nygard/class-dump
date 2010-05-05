// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDOCProtocol.h"
#import "CDTopologicalSortProtocol.h"

@class CDSymbolReferences;

@interface CDOCCategory : CDOCProtocol <CDTopologicalSort>
{
    NSString *className;
}

- (void)dealloc;

- (NSString *)className;
- (void)setClassName:(NSString *)newClassName;

- (NSString *)sortableName;

- (NSString *)findTag:(CDSymbolReferences *)symbolReferences;
- (void)recursivelyVisit:(CDVisitor *)aVisitor;

// CDTopologicalSort protocol
- (NSString *)identifier;
- (NSArray *)dependancies;

@end
