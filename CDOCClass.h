//
// $Id: CDOCClass.h,v 1.18 2004/02/11 01:19:54 nygard Exp $
//

//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

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

- (void)appendToString:(NSMutableString *)resultString classDump:(CDClassDump *)aClassDump symbolReferences:(CDSymbolReferences *)symbolReferences;
- (void)registerStructuresWithObject:(id <CDStructureRegistration>)anObject phase:(int)phase;

// CDTopologicalSort protocol
- (NSString *)identifier;
- (NSArray *)dependancies;

@end

