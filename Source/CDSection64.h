// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDSection.h"

@class CDMachOFileDataCursor, CDLCSegment64;

@interface CDSection64 : CDSection

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor segment:(CDLCSegment64 *)segment;

@property (weak, readonly) CDLCSegment64 *segment;

- (void)loadData;

- (BOOL)containsAddress:(NSUInteger)address;
- (NSUInteger)fileOffsetForAddress:(NSUInteger)address;

@end
