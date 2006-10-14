//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2006  Steve Nygard

#import "CDLoadCommand.h"

@class NSMutableArray;

@interface CDSymbolTable : CDLoadCommand
{
    struct symtab_command symtabCommand;
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
