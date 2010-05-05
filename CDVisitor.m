// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDVisitor.h"

#import "CDClassDump.h"
#import "CDObjectiveC1Processor.h"
#import "CDOCProperty.h"
#import "CDVisitorPropertyState.h"

@implementation CDVisitor

- (id)init;
{
    if ([super init] == nil)
        return nil;

    classDump = nil;

    return self;
}

- (void)dealloc;
{
    [classDump release];

    [super dealloc];
}

- (CDClassDump *)classDump;
{
    return classDump;
}

- (void)setClassDump:(CDClassDump *)newClassDump;
{
    if (newClassDump == classDump)
        return;

    [classDump release];
    classDump = [newClassDump retain];
}

- (void)willBeginVisiting;
{
}

- (void)didEndVisiting;
{
}

// Called before visiting.
- (void)willVisitObjectiveCProcessor:(CDObjectiveCProcessor *)aProcessor;
{
}

// This gets called before visiting the children, but only if it has children it will visit.
- (void)visitObjectiveCProcessor:(CDObjectiveCProcessor *)aProcessor;
{
}

- (void)willVisitPropertiesOfProtocol:(CDOCProtocol *)aProtocol;
{
}

- (void)didVisitPropertiesOfProtocol:(CDOCProtocol *)aProtocol;
{
}

- (void)willVisitOptionalMethods;
{
}

- (void)didVisitOptionalMethods;
{
}

// Called after visiting.
- (void)didVisitObjectiveCProcessor:(CDObjectiveCProcessor *)aProcessor;
{
}

- (void)willVisitProtocol:(CDOCProtocol *)aProtocol;
{
}

- (void)didVisitProtocol:(CDOCProtocol *)aProtocol;
{
}

- (void)willVisitClass:(CDOCClass *)aClass;
{
}

- (void)didVisitClass:(CDOCClass *)aClass;
{
}

- (void)willVisitIvarsOfClass:(CDOCClass *)aClass;
{
}

- (void)didVisitIvarsOfClass:(CDOCClass *)aClass;
{
}

- (void)willVisitPropertiesOfClass:(CDOCClass *)aClass;
{
}

- (void)didVisitPropertiesOfClass:(CDOCClass *)aClass;
{
}

- (void)willVisitCategory:(CDOCCategory *)aCategory;
{
}

- (void)didVisitCategory:(CDOCCategory *)aCategory;
{
}

- (void)willVisitPropertiesOfCategory:(CDOCCategory *)aCategory;
{
}

- (void)didVisitPropertiesOfCategory:(CDOCCategory *)aCategory;
{
}

- (void)visitClassMethod:(CDOCMethod *)aMethod;
{
}

- (void)visitInstanceMethod:(CDOCMethod *)aMethod propertyState:(CDVisitorPropertyState *)propertyState;
{
}

- (void)visitIvar:(CDOCIvar *)anIvar;
{
}

- (void)visitProperty:(CDOCProperty *)aProperty;
{
}

- (void)visitRemainingProperties:(CDVisitorPropertyState *)propertyState;
{
}

@end
