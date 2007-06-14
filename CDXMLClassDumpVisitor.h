// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2007 Steve Nygard.  All rights reserved.

#import "CDVisitor.h"

@interface CDXMLClassDumpVisitor : CDVisitor
{
    NSXMLDocument *xmlDocument;
}

- (id)init;
- (void)dealloc;

- (void)_setXMLDocument:(NSXMLDocument *)newXMLDocument;

- (void)willBeginVisiting;
- (void)didEndVisiting;

- (void)writeResultToStandardOutput;

- (void)visitObjectiveCSegmentProcessor:(CDObjCSegmentProcessor *)anObjCSegmentProcessor;

@end
