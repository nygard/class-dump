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
- (void)willVisitObjectiveCSegmentProcessor:(CDObjCSegmentProcessor *)anObjCSegmentProcessor;
{
    NSLog(@" > %s", _cmd);
    NSLog(@"<  %s", _cmd);
}

// This gets called before visiting the children, but only if it has children it will visit.
- (void)visitObjectiveCSegmentProcessor:(CDObjCSegmentProcessor *)anObjCSegmentProcessor;
{
    NSLog(@" > %s", _cmd);
    NSLog(@"<  %s", _cmd);
}

// Called after visiting.
- (void)didVisitObjectiveCSegmentProcessor:(CDObjCSegmentProcessor *)anObjCSegmentProcessor;
{
    NSLog(@" > %s", _cmd);
    NSLog(@"<  %s", _cmd);
}

- (void)willVisitProtocol:(CDOCProtocol *)aProtocol;
{
    NSLog(@" > %s", _cmd);
    NSLog(@"<  %s", _cmd);
}

- (void)didVisitProtocol:(CDOCProtocol *)aProtocol;
{
    NSLog(@" > %s", _cmd);
    NSLog(@"<  %s", _cmd);
}

@end
