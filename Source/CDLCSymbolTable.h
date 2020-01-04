// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "CDLoadCommand.h"

@class CDSymbol;

@interface CDLCSymbolTable : CDLoadCommand

- (void)loadSymbols;

@property (nonatomic, readonly) uint32_t symoff;
@property (nonatomic, readonly) uint32_t nsyms;
@property (nonatomic, readonly) uint32_t stroff;
@property (nonatomic, readonly) uint32_t strsize;

@property (nonatomic, readonly) NSUInteger baseAddress;
@property (nonatomic, readonly) NSArray *symbols;

- (CDSymbol *)symbolForClassName:(NSString *)className;
- (CDSymbol *)symbolForExternalClassName:(NSString *)className;

@end
