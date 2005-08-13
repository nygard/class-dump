//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2005  Steve Nygard

#import "CDLoadCommand.h"
#include <mach-o/loader.h>

@class NSArray;
@class CDSection;

@interface CDSegmentCommand : CDLoadCommand
{
    struct segment_command segmentCommand;

    NSString *name;
    NSArray *sections;
}

- (id)initWithPointer:(const void *)ptr machOFile:(CDMachOFile *)aMachOFile;
- (void)dealloc;

- (void)_processSectionsWithPointer:(const void *)ptr;

- (NSString *)name;
- (unsigned long)vmaddr;
- (unsigned long)fileoff;
- (unsigned long)flags;
- (NSArray *)sections;

- (NSString *)flagDescription;
- (NSString *)extraDescription;

- (BOOL)containsAddress:(unsigned long)vmaddr;
- (unsigned long)segmentOffsetForVMAddr:(unsigned long)vmaddr;

- (CDSection *)sectionWithName:(NSString *)aName;

@end
