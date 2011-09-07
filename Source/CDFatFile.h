// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2011 Steve Nygard.

#import "CDFile.h"

@class CDFatArch, CDMachOFile;

@interface CDFatFile : CDFile
{
    NSArray *arches;
}

- (id)initWithData:(NSData *)someData archOffset:(NSUInteger)anOffset archSize:(NSUInteger)aSize filename:(NSString *)aFilename searchPathState:(CDSearchPathState *)aSearchPathState;

- (NSString *)description;

- (BOOL)bestMatchForLocalArch:(CDArch *)archPtr;
- (CDMachOFile *)machOFileWithArch:(CDArch)arch;

- (NSArray *)arches;
- (NSArray *)archNames;

@end
