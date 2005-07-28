//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import <Foundation/NSObject.h>
#include <mach-o/loader.h>

@class NSString;
@class CDMachOFile, CDSegmentCommand;

@interface CDSection : NSObject
{
    CDSegmentCommand *nonretainedSegment;

    struct section section;
    NSString *segmentName;
    NSString *sectionName;
}

- (id)initWithPointer:(const void *)ptr segment:(CDSegmentCommand *)aSegment;
- (void)dealloc;

- (CDSegmentCommand *)segment;
- (CDMachOFile *)machOFile;

- (NSString *)segmentName;
- (NSString *)sectionName;
- (unsigned long)addr;
- (unsigned long)size;
- (unsigned long)offset;

- (const void *)dataPointer; // Has no access to the mach-o file

- (NSString *)description;

- (BOOL)containsAddress:(unsigned long)vmaddr;
- (unsigned long)segmentOffsetForVMAddr:(unsigned long)vmaddr;

@end
