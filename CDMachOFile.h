// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import "CDFile.h"

#include <mach/machine.h> // For cpu_type_t, cpu_subtype_t
#include <mach-o/loader.h>

#import "CDDataCursor.h" // For CDByteOrder

@class CDLCSegment;
@class CDLCDylib, CDMachOFile, CDLCSymbolTable, CDLCDynamicSymbolTable;

@protocol CDMachOFileDelegate
- (void)machOFile:(CDMachOFile *)aMachOFile loadDylib:(CDLCDylib *)aDylibCommand;
@end

@interface CDMachOFile : CDFile
{
    CDByteOrder byteOrder;

    NSMutableArray *loadCommands;
    CDLCSymbolTable *symbolTable;
    CDLCDynamicSymbolTable *dynamicSymbolTable;

    struct {
        unsigned int uses64BitABI:1;
    } _flags;
}

- (id)initWithData:(NSData *)someData offset:(NSUInteger)anOffset;
- (void)dealloc;

- (void)_readLoadCommands:(CDDataCursor *)cursor count:(uint32_t)count;

- (CDByteOrder)byteOrder;

- (NSString *)bestMatchForLocalArch;
- (CDMachOFile *)machOFileWithArchName:(NSString *)name;

- (uint32_t)magic;
- (cpu_type_t)cputype;
- (cpu_subtype_t)cpusubtype;
- (uint32_t)filetype;
- (uint32_t)flags;

- (NSArray *)loadCommands;

- (CDLCSymbolTable *)symbolTable;
- (void)setSymbolTable:(CDLCSymbolTable *)newSymbolTable;

- (CDLCDynamicSymbolTable *)dynamicSymbolTable;
- (void)setDynamicSymbolTable:(CDLCDynamicSymbolTable *)newSymbolTable;

- (NSString *)filetypeDescription;
- (NSString *)flagDescription;

- (CDLCDylib *)dylibIdentifier;

- (CDLCSegment *)segmentWithName:(NSString *)segmentName;
- (CDLCSegment *)segmentContainingAddress:(NSUInteger)address;
- (NSString *)stringAtAddress:(NSUInteger)address;

- (const void *)machODataBytes;
- (NSUInteger)dataOffsetForAddress:(NSUInteger)address;
- (NSUInteger)dataOffsetForAddress:(NSUInteger)address segmentName:(NSString *)aSegmentName;

- (const void *)bytes;
- (const void *)bytesAtOffset:(NSUInteger)anOffset;

- (NSString *)importBaseName;

- (BOOL)hasProtectedSegments;

- (NSString *)loadCommandString:(BOOL)isVerbose;
- (NSString *)headerString:(BOOL)isVerbose;

- (NSString *)archName;

- (NSString *)description;

- (Class)processorClass;
- (void)logInfoForAddress:(NSUInteger)address;

- (NSString *)externalClassNameForAddress:(NSUInteger)address;

@end
