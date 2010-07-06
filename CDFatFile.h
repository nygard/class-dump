// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDFile.h"

@class CDFatArch, CDMachOFile;

@interface CDFatFile : CDFile
{
    NSMutableArray *arches;
}

- (id)initWithData:(NSData *)someData offset:(NSUInteger)anOffset filename:(NSString *)aFilename searchPathState:(CDSearchPathState *)aSearchPathState;
- (void)dealloc;

- (BOOL)bestMatchForLocalArch:(CDArch *)archPtr;
- (CDMachOFile *)machOFileWithArch:(CDArch)arch;

- (NSString *)description;

- (NSArray *)arches;
- (NSArray *)archNames;

@end
