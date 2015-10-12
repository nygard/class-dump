// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDVisitor.h"

#import "CDClassDump.h"

@implementation CDVisitor
{
    CDClassDump *_classDump;
    BOOL _shouldShowStructureSection;
    BOOL _shouldShowProtocolSection;
}

- (id)init;
{
    if ((self = [super init])) {
        _shouldShowStructureSection = YES;
        _shouldShowProtocolSection  = YES;
    }
    
    return self;
}

#pragma mark -

- (void)willBeginVisiting;
{
}

- (void)didEndVisiting;
{
}

// Called before visiting.
- (void)willVisitObjectiveCProcessor:(CDObjectiveCProcessor *)processor;
{
}

// This gets called before visiting the children, but only if it has children it will visit.
- (void)visitObjectiveCProcessor:(CDObjectiveCProcessor *)processor;
{
}

- (void)willVisitPropertiesOfProtocol:(CDOCProtocol *)protocol;
{
}

- (void)didVisitPropertiesOfProtocol:(CDOCProtocol *)protocol;
{
}

- (void)willVisitOptionalMethods;
{
}

- (void)didVisitOptionalMethods;
{
}

// Called after visiting.
- (void)didVisitObjectiveCProcessor:(CDObjectiveCProcessor *)processor;
{
}

- (void)willVisitProtocol:(CDOCProtocol *)protocol;
{
}

- (void)didVisitProtocol:(CDOCProtocol *)protocol;
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

- (void)willVisitCategory:(CDOCCategory *)category;
{
}

- (void)didVisitCategory:(CDOCCategory *)category;
{
}

- (void)willVisitPropertiesOfCategory:(CDOCCategory *)category;
{
}

- (void)didVisitPropertiesOfCategory:(CDOCCategory *)category;
{
}

- (void)visitClassMethod:(CDOCMethod *)method;
{
}

- (void)visitInstanceMethod:(CDOCMethod *)method propertyState:(CDVisitorPropertyState *)propertyState;
{
}

- (void)visitIvar:(CDOCInstanceVariable *)ivar;
{
}

- (void)visitProperty:(CDOCProperty *)property;
{
}

- (void)visitRemainingProperties:(CDVisitorPropertyState *)propertyState;
{
}

@end
