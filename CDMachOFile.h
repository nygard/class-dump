// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2011 Steve Nygard.

#import "CDFile.h"

#include <mach/machine.h> // For cpu_type_t, cpu_subtype_t
#include <mach-o/loader.h>

enum {
    CDByteOrder_LittleEndian = 0,
    CDByteOrder_BigEndian = 1,
};
typedef NSUInteger CDByteOrder;

@class CDLCSegment, CDMachOFileDataCursor;
@class CDLCDyldInfo, CDLCDylib, CDMachOFile, CDLCSymbolTable, CDLCDynamicSymbolTable, CDLCVersionMinimum;

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
    CDLCVersionMinimum *minVersionMacOSX;
    CDLCVersionMinimum *minVersionIOS;
    NSMutableArray *runPaths;
    struct mach_header_64 header; // 64-bit, also holding 32-bit

    struct {
        unsigned int uses64BitABI:1;
    } _flags;
}

- (id)initWithData:(NSData *)someData archOffset:(NSUInteger)anOffset archSize:(NSUInteger)aSize filename:(NSString *)aFilename searchPathState:(CDSearchPathState *)aSearchPathState;
- (void)dealloc;

- (void)_readLoadCommands:(CDMachOFileDataCursor *)cursor count:(uint32_t)count;

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
@property(retain) CDLCVersionMinimum *minVersionMacOSX;
@property(retain) CDLCVersionMinimum *minVersionIOS;

- (BOOL)uses64BitABI;
- (NSUInteger)ptrSize;

- (NSString *)filetypeDescription;
- (NSString *)flagDescription;

- (CDLCDylib *)dylibIdentifier;

- (CDLCSegment *)segmentWithName:(NSString *)segmentName;
- (CDLCSegment *)segmentContainingAddress:(NSUInteger)address;
- (NSString *)stringAtAddress:(NSUInteger)address;

- (NSData *)machOData;
- (NSUInteger)dataOffsetForAddress:(NSUInteger)address;

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
- (Class)processorClass;

- (void)saveDeprotectedFileToPath:(NSString *)path;

- (NSArray *)runPaths;

@end
