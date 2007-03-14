//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2007  Steve Nygard

#import <Foundation/NSObject.h>

#include <mach-o/loader.h>

@class CDMachOFile;

@interface CDLoadCommand : NSObject
{
    CDMachOFile *nonretainedMachOFile;

    struct load_command loadCommand;
}

+ (id)loadCommandWithPointer:(const void *)ptr machOFile:(CDMachOFile *)aMachOFile;

- (id)initWithPointer:(const void *)ptr machOFile:(CDMachOFile *)aMachOFile;

- (CDMachOFile *)machOFile;

- (unsigned long)cmd;
- (unsigned long)cmdsize;

- (NSString *)commandName;
- (NSString *)description;
- (NSString *)extraDescription;

- (void)appendToString:(NSMutableString *)resultString verbose:(BOOL)isVerbose;

@end
