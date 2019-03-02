// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "CDLCLinkeditData.h"

@interface CDLCFunctionStarts : CDLCLinkeditData

@property (nonatomic, readonly) NSArray *functionStarts;

@end
