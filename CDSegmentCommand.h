//
// $Id: CDSegmentCommand.h,v 1.2 2004/01/06 01:51:56 nygard Exp $
//

//  This file is part of class-dump, a utility for exmaing the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import "CDLoadCommand.h"
#include <mach-o/loader.h>

@class NSArray;
@class CDSection;

@interface CDSegmentCommand : CDLoadCommand
{
    const struct segment_command *segmentCommand;

    NSString *name;
    NSArray *sections;
    //id contents;
}

- (id)initWithPointer:(const void *)ptr machOFile:(CDMachOFile *)aMachOFile;
- (void)dealloc;

- (void)_processSections;

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
