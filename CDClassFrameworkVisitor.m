//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2007 Steve Nygard.  All rights reserved.

#import "CDClassFrameworkVisitor.h"

#import "CDOCClass.h"
#import "CDObjCSegmentProcessor.h"
#import "CDMachOFile.h"

// This builds up a dictionary mapping class names to a framework name.  It is used to generate individual imports when creating separate header files.

@implementation CDClassFrameworkVisitor

- (id)init;
{
    if ([super init] == nil)
        return nil;

    frameworkNamesByClassName = [[NSMutableDictionary alloc] init];
    frameworkName = nil;

    return self;
}

- (void)dealloc;
{
    [frameworkNamesByClassName release];
    [frameworkName release];

    [super dealloc];
}

- (NSDictionary *)frameworkNamesByClassName;
{
    return frameworkNamesByClassName;
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

- (void)willVisitObjectiveCSegment:(CDObjCSegmentProcessor *)anObjCSegment;
{
    [self setFrameworkName:[[anObjCSegment machOFile] importBaseName]];
}

- (void)willVisitClass:(CDOCClass *)aClass;
{
    if (frameworkName != nil) {
        [frameworkNamesByClassName setObject:frameworkName forKey:[aClass name]];
    }
}

@end
