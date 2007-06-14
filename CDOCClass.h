//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2007  Steve Nygard

#import "CDOCProtocol.h"
#import "CDTopologicalSortProtocol.h"

@interface CDOCClass : CDOCProtocol <CDTopologicalSort>
{
    NSString *superClassName;
    NSArray *ivars;
}

- (void)dealloc;

- (NSString *)superClassName;
- (void)setSuperClassName:(NSString *)newSuperClassName;

- (NSArray *)ivars;
- (void)setIvars:(NSArray *)newIvars;

- (void)addToXMLElement:(NSXMLElement *)xmlElement classDump:(CDClassDump *)aClassDump symbolReferences:(CDSymbolReferences *)symbolReferences;
- (void)registerStructuresWithObject:(id <CDStructureRegistration>)anObject phase:(int)phase;

- (NSString *)findTag:(CDSymbolReferences *)symbolReferences;
- (void)recursivelyVisit:(CDVisitor *)aVisitor;

// CDTopologicalSort protocol
- (NSString *)identifier;
- (NSArray *)dependancies;

@end
