// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDVisitor.h"

@class CDSymbolReferences, CDType;

@interface CDTextClassDumpVisitor : CDVisitor
{
    NSMutableString *resultString;
    CDSymbolReferences *symbolReferences;
}

- (id)init;
- (void)dealloc;

- (void)writeResultToStandardOutput;

- (void)willVisitClass:(CDOCClass *)aClass;
- (void)didVisitClass:(CDOCClass *)aClass;

- (void)willVisitIvarsOfClass:(CDOCClass *)aClass;
- (void)didVisitIvarsOfClass:(CDOCClass *)aClass;

- (void)willVisitCategory:(CDOCCategory *)aCategory;
- (void)didVisitCategory:(CDOCCategory *)aCategory;

- (void)willVisitProtocol:(CDOCProtocol *)aProtocol;
- (void)didVisitProtocol:(CDOCProtocol *)aProtocol;

- (void)visitClassMethod:(CDOCMethod *)aMethod;
- (void)visitInstanceMethod:(CDOCMethod *)aMethod propertyState:(CDVisitorPropertyState *)propertyState;
- (void)visitIvar:(CDOCIvar *)anIvar;

- (void)_visitProperty:(CDOCProperty *)aProperty parsedType:(CDType *)parsedType attributes:(NSArray *)attrs;
- (void)visitProperty:(CDOCProperty *)aProperty;
- (void)didVisitPropertiesOfClass:(CDOCClass *)aClass;

- (void)willVisitPropertiesOfCategory:(CDOCCategory *)aCategory;
- (void)didVisitPropertiesOfCategory:(CDOCCategory *)aCategory;

- (void)willVisitPropertiesOfProtocol:(CDOCProtocol *)aProtocol;
- (void)didVisitPropertiesOfProtocol:(CDOCProtocol *)aProtocol;

- (void)visitRemainingProperties:(CDVisitorPropertyState *)propertyState;

@end
