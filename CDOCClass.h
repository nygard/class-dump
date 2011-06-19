// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2011 Steve Nygard.

#import "CDOCProtocol.h"
#import "CDTopologicalSortProtocol.h"

@interface CDOCClass : CDOCProtocol <CDTopologicalSort>
{
    NSString *superClassName;
    NSArray *ivars;

    BOOL isExported;
}

- (void)dealloc;

@property (retain) NSString *superClassName;
@property (retain) NSArray *ivars;
@property BOOL isExported;

- (void)registerTypesWithObject:(CDTypeController *)typeController phase:(NSUInteger)phase;

- (NSString *)findTag:(CDSymbolReferences *)symbolReferences;
- (void)recursivelyVisit:(CDVisitor *)aVisitor;

// CDTopologicalSort protocol
- (NSString *)identifier;
- (NSArray *)dependancies;

@end
