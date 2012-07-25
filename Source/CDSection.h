// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDDataCursor, CDMachOFile, CDLCSegment32;

@interface CDSection : NSObject

@property (retain) NSString *segmentName;
@property (retain) NSString *sectionName;

@property (nonatomic, strong) NSData *data;

@property (assign) BOOL hasLoadedData;
- (void)loadData;
- (void)unloadData;

@property (nonatomic, readonly) NSUInteger addr;
@property (nonatomic, readonly) NSUInteger size;

- (CDMachOFile *)machOFile;

- (BOOL)containsAddress:(NSUInteger)address;
- (NSUInteger)fileOffsetForAddress:(NSUInteger)address;

@end
