// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2011 Steve Nygard.

#import "CDVisitor.h"

@class CDSymbolReferences, CDType;

@interface CDTextClassDumpVisitor : CDVisitor
{
    NSMutableString *resultString;
    CDSymbolReferences *symbolReferences;
}

- (void)writeResultToStandardOutput;

- (void)_visitProperty:(CDOCProperty *)aProperty parsedType:(CDType *)parsedType attributes:(NSArray *)attrs;

@end
