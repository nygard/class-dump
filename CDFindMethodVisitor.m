//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2007 Steve Nygard.  All rights reserved.

#import "CDFindMethodVisitor.h"

#import "CDClassDump.h"
#import "CDObjCSegmentProcessor.h"

@implementation CDFindMethodVisitor

- (id)init;
{
    if ([super init] == nil)
        return nil;

    findString = nil;

    return self;
}

- (void)dealloc;
{
    [findString release];

    [super dealloc];
}

- (NSString *)findString;
{
    return findString;
}

- (void)setFindString:(NSString *)newFindString;
{
    if (newFindString == findString)
        return;

    [findString release];
    findString = [newFindString retain];
}

- (void)visitObjectiveCSegmentProcessor:(CDObjCSegmentProcessor *)anObjCSegmentProcessor;
{
}

@end
