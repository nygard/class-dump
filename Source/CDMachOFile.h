// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDFile.h"

#include <mach/machine.h> // For cpu_type_t, cpu_subtype_t
#include <mach-o/loader.h>

typedef enum : NSUInteger {
    CDByteOrder_LittleEndian = 0,
    CDByteOrder_BigEndian = 1,
} CDByteOrder;

@class CDLCSegment, CDMachOFileDataCursor;
@class CDLCDyldInfo, CDLCDylib, CDMachOFile, CDLCSymbolTable, CDLCDynamicSymbolTable, CDLCVersionMinimum, CDLCSourceVersion;

@protocol CDMachOFileDelegate
- (void)machOFile:(CDMachOFile *)machOFile loadDylib:(CDLCDylib *)dylibCommand;
@end

@interface CDMachOFile : CDFile

@property (readonly) CDByteOrder byteOrder;

@property (readonly) uint32_t magic;
@property (assign) cpu_type_t cputype;
@property (assign) cpu_subtype_t cpusubtype;
@property (readonly) uint32_t filetype;
@property (readonly) uint32_t flags;

@property (nonatomic, readonly) cpu_type_t maskedCPUType;
@property (nonatomic, readonly) cpu_subtype_t maskedCPUSubtype;

@property (readonly) NSArray *loadCommands;
@property (readonly) NSArray *dylibLoadCommands;
@property (readonly) NSArray *segments;
@property (readonly) NSArray *runPaths;
@property (readonly) NSArray *dyldEnvironment;
@property (readonly) NSArray *reExportedDylibs;

@property (strong) CDLCSymbolTable *symbolTable;
@property (strong) CDLCDynamicSymbolTable *dynamicSymbolTable;
@property (strong) CDLCDyldInfo *dyldInfo;
@property (strong) CDLCVersionMinimum *minVersionMacOSX;
@property (strong) CDLCVersionMinimum *minVersionIOS;
@property (strong) CDLCSourceVersion *sourceVersion;

@property (readonly) BOOL uses64BitABI;
- (NSUInteger)ptrSize;

- (NSString *)filetypeDescription;
- (NSString *)flagDescription;

@property (nonatomic, readonly) CDLCDylib *dylibIdentifier;

- (CDLCSegment *)segmentWithName:(NSString *)segmentName;
- (CDLCSegment *)segmentContainingAddress:(NSUInteger)address;
- (NSString *)stringAtAddress:(NSUInteger)address;

- (NSUInteger)dataOffsetForAddress:(NSUInteger)address;

- (const void *)bytes;
- (const void *)bytesAtOffset:(NSUInteger)offset;

@property (nonatomic, readonly) NSString *importBaseName;

@property (nonatomic, readonly) BOOL isEncrypted;
@property (nonatomic, readonly) BOOL hasProtectedSegments;
@property (nonatomic, readonly) BOOL canDecryptAllSegments;

- (NSString *)loadCommandString:(BOOL)isVerbose;
- (NSString *)headerString:(BOOL)isVerbose;

@property (nonatomic, readonly) NSString *uuidString;
@property (nonatomic, readonly) NSString *archName;

- (Class)processorClass;
- (void)logInfoForAddress:(NSUInteger)address;

- (NSString *)externalClassNameForAddress:(NSUInteger)address;
- (BOOL)hasRelocationEntryForAddress:(NSUInteger)address;

// Checks compressed dyld info on 10.6 or later.
- (BOOL)hasRelocationEntryForAddress2:(NSUInteger)address;
- (NSString *)externalClassNameForAddress2:(NSUInteger)address;

@property (nonatomic, readonly) BOOL hasObjectiveC1Data;
@property (nonatomic, readonly) BOOL hasObjectiveC2Data;
@property (nonatomic, readonly) Class processorClass;

@end
