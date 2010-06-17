// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import <Foundation/Foundation.h>

#include <mach-o/loader.h>
#include "dyld-info-compat.h"

@class CDDataCursor, CDMachOFile;

@interface CDLoadCommand : NSObject
{
    CDMachOFile *nonretained_machOFile;
    NSUInteger commandOffset;
}

+ (id)loadCommandWithDataCursor:(CDDataCursor *)cursor machOFile:(CDMachOFile *)aMachOFile;

- (id)initWithDataCursor:(CDDataCursor *)cursor machOFile:(CDMachOFile *)aMachOFile;

- (CDMachOFile *)machOFile;
- (NSUInteger)commandOffset;

- (uint32_t)cmd;
- (uint32_t)cmdsize;

- (NSString *)commandName;
- (NSString *)description;
- (NSString *)extraDescription;

- (void)appendToString:(NSMutableString *)resultString verbose:(BOOL)isVerbose;

- (BOOL)mustUnderstandToExecute;

@end
