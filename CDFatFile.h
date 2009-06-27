// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import "CDFile.h"

@class CDFatArch, CDMachOFile;

@interface CDFatFile : CDFile
{
    NSMutableArray *arches;
}

- (id)initWithData:(NSData *)someData offset:(NSUInteger)anOffset;
- (void)dealloc;

- (CDArch)bestMatchForLocalArch;
- (CDMachOFile *)machOFileWithArch:(CDArch)arch;

- (NSString *)description;

- (NSArray *)arches;
- (NSArray *)archNames;

@end
