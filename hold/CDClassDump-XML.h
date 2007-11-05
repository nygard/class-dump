// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2007 Steve Nygard.  All rights reserved.

#import "CDClassDump.h"

@interface CDClassDump (XML)

+ (NSString *)currentPublicID;
+ (NSString *)currentSystemID;

@end
