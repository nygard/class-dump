// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDFile.h"

#include <mach/machine.h> // For cpu_type_t, cpu_subtype_t
#include <mach-o/loader.h>

#import "CDDataCursor.h" // For CDByteOrder

@class CDLCSegment;
@class CDLCDyldInfo, CDLCDylib, CDMachOFile, CDLCSymbolTable, CDLCDynamicSymbolTable;

@protocol CDMachOFileDelegate
- (void)machOFile:(CDMachOFile *)aMachOFile loadDylib:(CDLCDylib *)aDylibCommand;
@end

@interface CDMachOFile : CDFile
{
    CDByteOrder byteOrder;

    NSMutableArray *loadCommands;
    NSMutableArray *segments;
    CDLCSymbolTable *symbolTable;
    CDLCDynamicSymbolTable *dynamicSymbolTable;
    CDLCDyldInfo *dyldInfo;
    NSMutableArray *runPaths;

    struct {
        unsigned int uses64BitABI:1;
    } _flags;
}

- (id)initWithData:(NSData *)someData offset:(NSUInteger)anOffset filename:(NSString *)aFilename searchPathState:(CDSearchPathState *)aSearchPathState;
- (void)dealloc;

- (void)_readLoadCommands:(CDDataCursor *)cursor count:(uint32_t)count;

- (CDByteOrder)byteOrder;

- (CDMachOFile *)machOFileWithArch:(CDArch)arch;

- (uint32_t)magic;
- (cpu_type_t)cputype;
- (cpu_subtype_t)cpusubtype;
- (cpu_type_t)cputypePlusArchBits;
//- (const NXArchInfo *)archInfo;
- (uint32_t)filetype;
- (uint32_t)flags;

- (NSArray *)loadCommands;
- (NSArray *)dylibLoadCommands;
- (NSArray *)segments;

@property(retain) CDLCSymbolTable *symbolTable;
@property(retain) CDLCDynamicSymbolTable *dynamicSymbolTable;
@property(retain) CDLCDyldInfo *dyldInfo;

- (BOOL)uses64BitABI;

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

- (BOOL)isEncrypted;
- (BOOL)hasProtectedSegments;
- (BOOL)canDecryptAllSegments;

- (NSString *)loadCommandString:(BOOL)isVerbose;
- (NSString *)headerString:(BOOL)isVerbose;

- (NSString *)uuidString;
- (NSString *)archName;

- (NSString *)description;

- (Class)processorClass;
- (void)logInfoForAddress:(NSUInteger)address;

- (NSString *)externalClassNameForAddress:(NSUInteger)address;
- (BOOL)hasRelocationEntryForAddress:(NSUInteger)address;

// Checks compressed dyld info on 10.6 or later.
- (BOOL)hasRelocationEntryForAddress2:(NSUInteger)address;
- (NSString *)externalClassNameForAddress2:(NSUInteger)address;

- (BOOL)hasObjectiveC1Data;
- (BOOL)hasObjectiveC2Data;

- (void)saveDeprotectedFileToPath:(NSString *)path;

- (NSArray *)runPaths;

@end
