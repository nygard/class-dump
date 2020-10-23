// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "CDObjectiveCProcessor.h"

#define METHOD_LIST_T_RESERVED_BITS 0x7FFF0003
#define METHOD_LIST_T_SMALL_METHOD_FLAG 0x80000000
#define METHOD_LIST_T_ENTSIZE_MASK (METHOD_LIST_T_RESERVED_BITS|METHOD_LIST_T_SMALL_METHOD_FLAG)

@interface CDObjectiveC2Processor : CDObjectiveCProcessor

@end
