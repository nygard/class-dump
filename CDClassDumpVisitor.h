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

- (void)visitObjectiveCSegment:(CDObjCSegmentProcessor *)anObjCSegment;

- (void)willVisitProtocol:(CDOCProtocol *)aProtocol;
- (void)didVisitProtocol:(CDOCProtocol *)aProtocol;

- (void)willVisitClass:(CDOCClass *)aClass;
- (void)didVisitClass:(CDOCClass *)aClass;

- (void)willVisitIvarsOfClass:(CDOCClass *)aClass;
- (void)didVisitIvarsOfClass:(CDOCClass *)aClass;

- (void)willVisitCategory:(CDOCCategory *)aCategory;
- (void)didVisitCategory:(CDOCCategory *)aCategory;

- (void)visitClassMethod:(CDOCMethod *)aMethod;
- (void)visitInstanceMethod:(CDOCMethod *)aMethod;

- (void)visitIvar:(CDOCIvar *)anIvar;

@end
