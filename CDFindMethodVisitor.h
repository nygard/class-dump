// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDVisitor.h"

@interface CDFindMethodVisitor : CDVisitor
{
    NSString *findString;
    NSMutableString *resultString;
    CDOCProtocol *context;
    BOOL hasShownContext;
}

- (id)init;
- (void)dealloc;

- (NSString *)findString;
- (void)setFindString:(NSString *)newFindString;

- (void)setContext:(CDOCProtocol *)newContext;
- (void)showContextIfNecessary;

- (void)willBeginVisiting;
- (void)didEndVisiting;

- (void)writeResultToStandardOutput;

- (void)willVisitProtocol:(CDOCProtocol *)aProtocol;
- (void)didVisitProtocol:(CDOCProtocol *)aProtocol;

- (void)willVisitClass:(CDOCClass *)aClass;
- (void)didVisitClass:(CDOCClass *)aClass;

- (void)willVisitIvarsOfClass:(CDOCClass *)aClass;
- (void)didVisitIvarsOfClass:(CDOCClass *)aClass;

- (void)willVisitCategory:(CDOCCategory *)aCategory;
- (void)didVisitCategory:(CDOCCategory *)aCategory;

- (void)visitClassMethod:(CDOCMethod *)aMethod;
- (void)visitInstanceMethod:(CDOCMethod *)aMethod propertyState:(CDVisitorPropertyState *)propertyState;

- (void)visitIvar:(CDOCIvar *)anIvar;

@end
