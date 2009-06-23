// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2007  Steve Nygard

#import "CDLoadCommand.h"
#include <mach-o/loader.h>

@class CDSection;

@interface CDSegmentCommand : CDLoadCommand
{
    struct segment_command segmentCommand;

    NSString *name;
    NSMutableArray *sections;

    NSMutableData *decryptedData;
}

- (id)initWithDataCursor:(CDDataCursor *)cursor machOFile:(CDMachOFile *)aMachOFile;
- (void)dealloc;

- (uint32_t)cmd;
- (uint32_t)cmdsize;

- (NSString *)name;
- (uint32_t)vmaddr;
- (uint32_t)fileoff;
- (uint32_t)flags;
- (NSArray *)sections;

- (BOOL)isProtected;

- (NSString *)flagDescription;
- (NSString *)extraDescription;

//- (const void *)segmentDataBytes;

- (BOOL)containsAddress:(uint32_t)vmaddr;
- (CDSection *)sectionContainingAddress:(uint32_t)vmaddr;
- (CDSection *)sectionWithName:(NSString *)aName;
//- (uint32_t)segmentOffsetForVMAddr:(uint32_t)vmaddr;
- (uint32_t)fileOffsetForAddress:(uint32_t)address;

- (void)appendToString:(NSMutableString *)resultString verbose:(BOOL)isVerbose;

- (void)writeSectionData;

- (NSData *)decryptedData;

@end
