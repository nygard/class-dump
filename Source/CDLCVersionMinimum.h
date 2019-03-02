// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "CDLoadCommand.h"

@interface CDLCVersionMinimum : CDLoadCommand

@property (nonatomic, readonly) NSString *minimumVersionString;
@property (nonatomic, readonly) NSString *SDKVersionString;

@end
