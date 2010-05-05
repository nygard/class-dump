// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import <Foundation/Foundation.h>
#include <mach-o/loader.h>

@class CDDataCursor, CDMachOFile, CDLCSegment32;

@interface CDSection : NSObject
{
    NSString *segmentName;
    NSString *sectionName;

    NSData *data;
    struct {
        unsigned int hasLoadedData:1;
    } _flags;
}

- (id)init;
- (void)dealloc;

- (NSString *)segmentName;
- (void)setSegmentName:(NSString *)newName;

- (NSString *)sectionName;
- (void)setSectionName:(NSString *)newName;

- (NSData *)data;
- (void)loadData;
- (void)unloadData;

- (NSUInteger)addr;
- (NSUInteger)size;

- (CDMachOFile *)machOFile;

- (NSString *)description;

- (BOOL)containsAddress:(NSUInteger)address;
- (NSUInteger)fileOffsetForAddress:(NSUInteger)address;

@end
