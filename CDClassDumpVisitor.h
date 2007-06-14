// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2007 Steve Nygard.  All rights reserved.

#import "CDVisitor.h"

@interface CDClassDumpVisitor : CDVisitor
{
    NSMutableString *resultString;
}

- (id)init;
- (void)dealloc;

- (void)willBeginVisiting;
- (void)didEndVisiting;

- (void)writeResultToStandardOutput;

- (void)visitObjectiveCSegmentProcessor:(CDObjCSegmentProcessor *)anObjCSegmentProcessor;

- (void)willVisitProtocol:(CDOCProtocol *)aProtocol;
- (void)didVisitProtocol:(CDOCProtocol *)aProtocol;

@end
