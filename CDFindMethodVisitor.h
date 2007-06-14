// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2007 Steve Nygard.  All rights reserved.

#import "CDVisitor.h"

@interface CDFindMethodVisitor : CDVisitor
{
    NSString *findString;
}

- (id)init;
- (void)dealloc;

- (NSString *)findString;
- (void)setFindString:(NSString *)newFindString;

- (void)visitObjectiveCSegment:(CDObjCSegmentProcessor *)anObjCSegment;

@end
