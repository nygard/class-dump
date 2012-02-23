// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

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

- (id)initWithData:(NSData *)someData archOffset:(NSUInteger)anOffset archSize:(NSUInteger)aSize filename:(NSString *)aFilename searchPathState:(CDSearchPathState *)aSearchPathState;

- (NSString *)description;

- (void)_readLoadCommands:(CDMachOFileDataCursor *)cursor count:(uint32_t)count;

@property (readonly) CDByteOrder byteOrder;

- (CDMachOFile *)machOFileWithArch:(CDArch)arch;

@property (readonly) uint32_t magic;
@property (readonly) cpu_type_t cputype;
@property (readonly) cpu_subtype_t cpusubtype;
@property (readonly) cpu_type_t cputypePlusArchBits;
@property (readonly) uint32_t filetype;
@property (readonly) uint32_t flags;

@property (readonly) NSArray *loadCommands;
@property (readonly) NSArray *dylibLoadCommands;
@property (readonly) NSArray *segments;
@property (readonly) NSArray *runPaths;
@property (readonly) NSArray *dyldEnvironment;
@property (readonly) NSArray *reExportedDylibs;

@property (retain) CDLCSymbolTable *symbolTable;
@property (retain) CDLCDynamicSymbolTable *dynamicSymbolTable;
@property (retain) CDLCDyldInfo *dyldInfo;
@property (retain) CDLCVersionMinimum *minVersionMacOSX;
@property (retain) CDLCVersionMinimum *minVersionIOS;

- (BOOL)uses64BitABI;
- (NSUInteger)ptrSize;

- (NSString *)filetypeDescription;
- (NSString *)flagDescription;

@property (nonatomic, readonly) CDLCDylib *dylibIdentifier;

- (CDLCSegment *)segmentWithName:(NSString *)segmentName;
- (CDLCSegment *)segmentContainingAddress:(NSUInteger)address;
- (NSString *)stringAtAddress:(NSUInteger)address;

- (NSData *)machOData;
- (NSUInteger)dataOffsetForAddress:(NSUInteger)address;

- (const void *)bytes;
- (const void *)bytesAtOffset:(NSUInteger)anOffset;

@property (nonatomic, readonly) NSString *importBaseName;

@property (readonly) BOOL isEncrypted;
@property (readonly) BOOL hasProtectedSegments;
@property (readonly) BOOL canDecryptAllSegments;

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

@property (readonly) BOOL hasObjectiveC1Data;
@property (readonly) BOOL hasObjectiveC2Data;
@property (readonly) Class processorClass;

@end
