//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2004 Steve Nygard.  All rights reserved.

#import "CDLoadCommand.h"

@class NSMutableArray;

@interface CDSymtabCommand : CDLoadCommand
{
    const struct symtab_command *symtabCommand;
    NSMutableArray *symbols;
}

- (id)initWithPointer:(const void *)ptr machOFile:(CDMachOFile *)aMachOFile;
- (void)dealloc;

- (void)_process;

- (unsigned long)symoff;
- (unsigned long)nsyms;
- (unsigned long)stroff;
- (unsigned long)strsize;

- (NSString *)extraDescription;

@end
