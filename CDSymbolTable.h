// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import "CDLoadCommand.h"

@class NSMutableArray;

@interface CDSymbolTable : CDLoadCommand
{
    struct symtab_command symtabCommand;

    NSMutableArray *symbols;
}

- (id)initWithDataCursor:(CDDataCursor *)cursor machOFile:(CDMachOFile *)aMachOFile;
- (void)dealloc;

- (uint32_t)cmd;
- (uint32_t)cmdsize;

- (void)_process;

- (uint32_t)symoff;
- (uint32_t)nsyms;
- (uint32_t)stroff;
- (uint32_t)strsize;

- (NSString *)extraDescription;

@end
