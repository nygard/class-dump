// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2011 Steve Nygard.

#import "CDVisitor.h"

@class CDSymbolReferences;

@interface CDXMLClassDumpVisitor : CDVisitor
{
    NSXMLDocument *xmlDocument;
    NSMutableArray *elementStack;
    CDSymbolReferences *symbolReferences;
}

- (id)init;
- (void)dealloc;

- (void)_setXMLDocument:(NSXMLDocument *)newXMLDocument;

- (void)pushElement:(NSXMLElement *)anElement;
- (void)popElement;
- (NSXMLElement *)currentElement;

- (void)willBeginVisiting;
- (void)didEndVisiting;

- (void)writeResultToStandardOutput;

- (void)willVisitObjectiveCSegment:(CDObjCSegmentProcessor *)anObjCSegment;
- (void)visitObjectiveCSegment:(CDObjCSegmentProcessor *)anObjCSegment;
- (void)didVisitObjectiveCSegment:(CDObjCSegmentProcessor *)anObjCSegment;

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
