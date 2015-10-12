// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDFile.h"

@class CDFatArch;

@interface CDFatFile : CDFile

@property (readonly) NSMutableArray *arches;
@property (nonatomic, readonly) NSArray *archNames;

- (void)addArchitecture:(CDFatArch *)fatArch;
- (BOOL)containsArchitecture:(CDArch)arch;

@end
