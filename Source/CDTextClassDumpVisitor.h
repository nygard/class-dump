// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDVisitor.h"

// Has a mutable string for storing output, and method to write it to standard out.
// symbol references are for... ?

@interface CDTextClassDumpVisitor : CDVisitor

@property (readonly) NSMutableString *resultString;

- (void)writeResultToStandardOutput;

@end
