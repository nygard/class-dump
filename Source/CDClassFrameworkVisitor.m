// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2011 Steve Nygard.

#import "CDClassFrameworkVisitor.h"

#import "CDOCClass.h"
#import "CDObjectiveCProcessor.h"
#import "CDMachOFile.h"

// This builds up a dictionary mapping class names to a framework name.  It is used to generate individual imports when creating separate header files.

@implementation CDClassFrameworkVisitor

- (id)init;
{
    if ((self = [super init])) {
        frameworkNamesByClassName = [[NSMutableDictionary alloc] init];
        frameworkNamesByProtocolName = [[NSMutableDictionary alloc] init];
        frameworkName = nil;
    }

    return self;
}

- (void)dealloc;
{
    [frameworkNamesByClassName release];
    [frameworkNamesByProtocolName release];
    [frameworkName release];

    [super dealloc];
}

#pragma mark -

- (NSDictionary *)frameworkNamesByClassName;
{
    return frameworkNamesByClassName;
}

- (NSDictionary *)frameworkNamesByProtocolName;
{
    return frameworkNamesByProtocolName;
}

@synthesize frameworkName;

- (void)willVisitObjectiveCProcessor:(CDObjectiveCProcessor *)anObjCSegment;
{
    [self setFrameworkName:[[anObjCSegment machOFile] importBaseName]];
}

- (void)willVisitClass:(CDOCClass *)aClass;
{
    if (frameworkName != nil) {
        [frameworkNamesByClassName setObject:frameworkName forKey:[aClass name]];
    }
}

- (void)willVisitProtocol:(CDOCProtocol *)aProtocol;
{
    if (frameworkName != nil) {
        [frameworkNamesByProtocolName setObject:frameworkName forKey:[aProtocol name]];
    }
}

@end
