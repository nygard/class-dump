// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDSection.h"

@class CDMachOFileDataCursor, CDLCSegment32;

@interface CDSection32 : CDSection

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor segment:(CDLCSegment32 *)segment;

@property (weak, readonly) CDLCSegment32 *segment;
@property (nonatomic, readonly) uint32_t offset;

@end
