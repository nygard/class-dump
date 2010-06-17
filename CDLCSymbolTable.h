// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDLoadCommand.h"

@class CDSymbol;

@interface CDLCSymbolTable : CDLoadCommand
{
    struct symtab_command symtabCommand;

    NSMutableArray *symbols;
    NSUInteger baseAddress;

    NSMutableDictionary *classSymbols;

    struct {
        unsigned int didFindBaseAddress:1;
        unsigned int didWarnAboutUnfoundBaseAddress:1;
    } flags;
}

- (id)initWithDataCursor:(CDDataCursor *)cursor machOFile:(CDMachOFile *)aMachOFile;
- (void)dealloc;

- (uint32_t)cmd;
- (uint32_t)cmdsize;

- (void)loadSymbols;

- (uint32_t)symoff;
- (uint32_t)nsyms;
- (uint32_t)stroff;
- (uint32_t)strsize;

- (NSUInteger)baseAddress;
- (NSArray *)symbols;

- (CDSymbol *)symbolForClass:(NSString *)className;

- (NSString *)extraDescription;

@end
