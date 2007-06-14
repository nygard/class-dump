//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2007 Steve Nygard.  All rights reserved.

#import "CDVisitor.h"

#import "CDClassDump.h"
#import "CDObjCSegmentProcessor.h"

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
- (void)willVisitObjectiveCSegment:(CDObjCSegmentProcessor *)anObjCSegment;
{
    NSLog(@" > %s", _cmd);
    NSLog(@"<  %s", _cmd);
}

// This gets called before visiting the children, but only if it has children it will visit.
- (void)visitObjectiveCSegment:(CDObjCSegmentProcessor *)anObjCSegment;
{
    NSLog(@" > %s", _cmd);
    NSLog(@"<  %s", _cmd);
}

// Called after visiting.
- (void)didVisitObjectiveCSegment:(CDObjCSegmentProcessor *)anObjCSegment;
{
    NSLog(@" > %s", _cmd);
    NSLog(@"<  %s", _cmd);
}

- (void)willVisitProtocol:(CDOCProtocol *)aProtocol;
{
    NSLog(@" > %s", _cmd);
    NSLog(@"aProtocol: %@", aProtocol);
    NSLog(@"<  %s", _cmd);
}

- (void)didVisitProtocol:(CDOCProtocol *)aProtocol;
{
    NSLog(@" > %s", _cmd);
    NSLog(@"aProtocol: %@", aProtocol);
    NSLog(@"<  %s", _cmd);
}

- (void)willVisitClass:(CDOCClass *)aClass;
{
    NSLog(@" > %s", _cmd);
    NSLog(@"class: %@", aClass);
    NSLog(@"<  %s", _cmd);
}

- (void)didVisitClass:(CDOCClass *)aClass;
{
    NSLog(@" > %s", _cmd);
    NSLog(@"class: %@", aClass);
    NSLog(@"<  %s", _cmd);
}

- (void)willVisitIvarsOfClass:(CDOCClass *)aClass;
{
    NSLog(@" > %s", _cmd);
    NSLog(@"class: %@", aClass);
    NSLog(@"<  %s", _cmd);
}

- (void)didVisitIvarsOfClass:(CDOCClass *)aClass;
{
    NSLog(@" > %s", _cmd);
    NSLog(@"class: %@", aClass);
    NSLog(@"<  %s", _cmd);
}

- (void)willVisitCategory:(CDOCCategory *)aCategory;
{
    NSLog(@" > %s", _cmd);
    NSLog(@"category: %@", aCategory);
    NSLog(@"<  %s", _cmd);
}

- (void)didVisitCategory:(CDOCCategory *)aCategory;
{
    NSLog(@" > %s", _cmd);
    NSLog(@"category: %@", aCategory);
    NSLog(@"<  %s", _cmd);
}

- (void)visitClassMethod:(CDOCMethod *)aMethod;
{
    NSLog(@" > %s", _cmd);
    NSLog(@"method: %@", aMethod);
    NSLog(@"<  %s", _cmd);
}

- (void)visitInstanceMethod:(CDOCMethod *)aMethod;
{
    NSLog(@" > %s", _cmd);
    NSLog(@"method: %@", aMethod);
    NSLog(@"<  %s", _cmd);
}

- (void)visitIvar:(CDOCIvar *)anIvar;
{
    NSLog(@" > %s", _cmd);
    NSLog(@"ivar: %@", anIvar);
    NSLog(@"<  %s", _cmd);
}

@end
