// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDLoadCommand.h"

@class CDSymbol;

@interface CDLCSymbolTable : CDLoadCommand
{
    struct symtab_command symtabCommand;

    NSArray *symbols;
    NSUInteger baseAddress;

    NSDictionary *classSymbols;

    struct {
        unsigned int didFindBaseAddress:1;
        unsigned int didWarnAboutUnfoundBaseAddress:1;
    } flags;
}

- (void)loadSymbols;

@property (readonly) uint32_t symoff;
@property (readonly) uint32_t nsyms;
@property (readonly) uint32_t stroff;
@property (readonly) uint32_t strsize;

@property (readonly) NSUInteger baseAddress;
@property (readonly) NSArray *symbols;

- (CDSymbol *)symbolForClass:(NSString *)className;

@end
