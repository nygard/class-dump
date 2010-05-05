// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDClassFrameworkVisitor.h"

#import "CDOCClass.h"
#import "CDObjectiveCProcessor.h"
#import "CDMachOFile.h"

// This builds up a dictionary mapping class names to a framework name.  It is used to generate individual imports when creating separate header files.

@implementation CDClassFrameworkVisitor

- (id)init;
{
    if ([super init] == nil)
        return nil;

    frameworkNamesByClassName = [[NSMutableDictionary alloc] init];
    frameworkNamesByProtocolName = [[NSMutableDictionary alloc] init];
    frameworkName = nil;

    return self;
}

- (void)dealloc;
{
    [frameworkNamesByClassName release];
    [frameworkNamesByProtocolName release];
    [frameworkName release];

    [super dealloc];
}

- (NSDictionary *)frameworkNamesByClassName;
{
    return frameworkNamesByClassName;
}

- (NSDictionary *)frameworkNamesByProtocolName;
{
    return frameworkNamesByProtocolName;
}

- (NSString *)frameworkName;
{
    return frameworkName;
}

- (void)setFrameworkName:(NSString *)newFrameworkName;
{
    if (newFrameworkName == frameworkName)
        return;

    [frameworkName release];
    frameworkName = [newFrameworkName retain];
}

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
