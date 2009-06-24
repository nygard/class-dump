// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDClassDump, CDObjectiveCProcessor, CDOCProtocol, CDOCMethod, CDOCIvar, CDOCClass, CDOCCategory;

@interface CDVisitor : NSObject
{
    CDClassDump *classDump;
}

- (id)init;
- (void)dealloc;

- (CDClassDump *)classDump;
- (void)setClassDump:(CDClassDump *)newClassDump;

- (void)willBeginVisiting;
- (void)didEndVisiting;

- (void)willVisitObjectiveCProcessor:(CDObjectiveCProcessor *)aProcessor;
- (void)visitObjectiveCProcessor:(CDObjectiveCProcessor *)aProcessor;
- (void)didVisitObjectiveCProcessor:(CDObjectiveCProcessor *)aProcessor;

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
