// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2007 Steve Nygard.  All rights reserved.

#import "CDTextClassDumpVisitor.h"

@interface CDClassDumpVisitor : CDTextClassDumpVisitor
{
}

- (void)willBeginVisiting;
- (void)didEndVisiting;

- (void)visitObjectiveCSegment:(CDObjCSegmentProcessor *)anObjCSegment;

- (void)willVisitProtocol:(CDOCProtocol *)aProtocol;
- (void)didVisitProtocol:(CDOCProtocol *)aProtocol;

@end
