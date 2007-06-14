// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2007 Steve Nygard.  All rights reserved.

#import "CDVisitor.h"

@interface CDClassFrameworkVisitor : CDVisitor
{
    NSMutableDictionary *frameworkNamesByClassName;
    NSString *frameworkName;
}

- (id)init;
- (void)dealloc;

- (NSDictionary *)frameworkNamesByClassName;

- (NSString *)frameworkName;
- (void)setFrameworkName:(NSString *)newFrameworkName;

- (void)willVisitObjectiveCSegment:(CDObjCSegmentProcessor *)anObjCSegment;
- (void)willVisitClass:(CDOCClass *)aClass;

@end
