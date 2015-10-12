// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

@class CDClassDump, CDObjectiveCProcessor, CDOCProtocol, CDOCMethod, CDOCInstanceVariable, CDOCClass, CDOCCategory, CDOCProperty;
@class CDVisitorPropertyState;

@interface CDVisitor : NSObject

@property (strong) CDClassDump *classDump;

- (void)willBeginVisiting;
- (void)didEndVisiting;

- (void)willVisitObjectiveCProcessor:(CDObjectiveCProcessor *)processor;
- (void)visitObjectiveCProcessor:(CDObjectiveCProcessor *)processor;
- (void)didVisitObjectiveCProcessor:(CDObjectiveCProcessor *)processor;

- (void)willVisitProtocol:(CDOCProtocol *)protocol;
- (void)didVisitProtocol:(CDOCProtocol *)protocol;

- (void)willVisitPropertiesOfProtocol:(CDOCProtocol *)protocol;
- (void)didVisitPropertiesOfProtocol:(CDOCProtocol *)protocol;

- (void)willVisitOptionalMethods;
- (void)didVisitOptionalMethods;

- (void)willVisitClass:(CDOCClass *)aClass;
- (void)didVisitClass:(CDOCClass *)aClass;

- (void)willVisitIvarsOfClass:(CDOCClass *)aClass;
- (void)didVisitIvarsOfClass:(CDOCClass *)aClass;

- (void)willVisitPropertiesOfClass:(CDOCClass *)aClass;
- (void)didVisitPropertiesOfClass:(CDOCClass *)aClass;

- (void)willVisitCategory:(CDOCCategory *)category;
- (void)didVisitCategory:(CDOCCategory *)category;

- (void)willVisitPropertiesOfCategory:(CDOCCategory *)category;
- (void)didVisitPropertiesOfCategory:(CDOCCategory *)category;

- (void)visitClassMethod:(CDOCMethod *)method;
- (void)visitInstanceMethod:(CDOCMethod *)method propertyState:(CDVisitorPropertyState *)propertyState;
- (void)visitIvar:(CDOCInstanceVariable *)ivar;
- (void)visitProperty:(CDOCProperty *)property;

- (void)visitRemainingProperties:(CDVisitorPropertyState *)propertyState;

@property (assign) BOOL shouldShowStructureSection;
@property (assign) BOOL shouldShowProtocolSection;

@end
