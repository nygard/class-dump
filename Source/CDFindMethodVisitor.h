// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2011 Steve Nygard.

#import "CDVisitor.h"

@interface CDFindMethodVisitor : CDVisitor
{
    NSString *findString;
    NSMutableString *resultString;
    CDOCProtocol *context;
    BOOL hasShownContext;
}

@property (retain) NSString *findString;

- (void)setContext:(CDOCProtocol *)newContext;
- (void)showContextIfNecessary;

- (void)writeResultToStandardOutput;

@end
