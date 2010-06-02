// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDLoadCommand.h"

@interface CDLCDyldInfo : CDLoadCommand
{
    struct dyld_info_command dyldInfoCommand;

    NSUInteger ptrSize;
    NSMutableDictionary *symbolNamesByAddress;
}

- (id)initWithDataCursor:(CDDataCursor *)cursor machOFile:(CDMachOFile *)aMachOFile;
- (void)dealloc;

- (uint32_t)cmd;
- (uint32_t)cmdsize;

- (NSString *)symbolNameForAddress:(NSUInteger)address;

// Rebasing
- (void)logRebaseInfo;
- (void)rebaseAddress:(uint64_t)address type:(uint8_t)type;

// Binding
- (void)logBindInfo;
- (void)logWeakBindInfo;
- (void)logLazyBindInfo;

- (void)logBindOps:(const uint8_t *)start end:(const uint8_t *)end isLazy:(BOOL)isLazy;

- (void)bindAddress:(uint64_t)address type:(uint8_t)type symbolName:(const char *)symbolName flags:(uint8_t)flags
             addend:(int64_t)addend libraryOrdinal:(int64_t)libraryOrdinal;

// Exported symbols
- (void)logExportedSymbols;
- (void)printSymbols:(const uint8_t *)start end:(const uint8_t *)end prefix:(NSString *)prefix offset:(uint32_t)offset;

@end
