// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDSection.h"

#import "CDFatFile.h"
#import "CDMachOFile.h"
#import "CDLCSegment32.h"

@implementation CDSection

// Just to resolve multiple different definitions...
- (id)init;
{
    if ([super init] == nil)
        return nil;

    segmentName = nil;
    sectionName = nil;

    data = nil;
    _flags.hasLoadedData = NO;

    return self;
}

- (void)dealloc;
{
    [segmentName release];
    [sectionName release];
    [data release];

    [super dealloc];
}

- (NSString *)segmentName;
{
    return segmentName;
}

- (void)setSegmentName:(NSString *)newName;
{
    if (newName == segmentName)
        return;

    [segmentName release];
    segmentName = [newName retain];
}

- (NSString *)sectionName;
{
    return sectionName;
}

- (void)setSectionName:(NSString *)newName;
{
    if (newName == sectionName)
        return;

    [sectionName release];
    sectionName = [newName retain];
}

- (NSData *)data;
{
    [self loadData];

    return data;
}

- (void)loadData;
{
    // Impelement in subclasses
}

- (void)unloadData;
{
    if (_flags.hasLoadedData) {
        _flags.hasLoadedData = NO;
        [data release];
        data = nil;
    }
}

- (NSUInteger)addr;
{
    // Implement in subclasses.
    return 0;
}

- (NSUInteger)size;
{
    // Implement in subclasses.
    return 0;
}

- (CDMachOFile *)machOFile;
{
    // Implement in subclass (for now).
    return nil;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> segment; '%@', section: '%-16s'",
                     NSStringFromClass([self class]), self,
                     segmentName, [sectionName UTF8String]];
}

- (BOOL)containsAddress:(NSUInteger)address;
{
    // implement in subclasses.
    return NO;
}

- (NSUInteger)fileOffsetForAddress:(NSUInteger)address;
{
    // implement in subclasses.
    return 0;
}

@end
