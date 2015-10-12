// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDVisitor.h"

// This limits the output to methods matching the search string.  Some context is included, so that you can see which class, category, or protocol
// contains the method.

@interface CDFindMethodVisitor : CDVisitor

@property (strong) NSString *searchString;

@end
