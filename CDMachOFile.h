// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2007  Steve Nygard

#import "CDFile.h"

#include <mach/machine.h> // For cpu_type_t, cpu_subtype_t
#include <mach-o/loader.h>

#import "CDDataCursor.h" // For CDByteOrder

@class NSData;
@class CDSegmentCommand;

@class NSArray;
@class CDDylibCommand, CDMachOFile;

@protocol CDMachOFileDelegate
- (void)machOFile:(CDMachOFile *)aMachOFile loadDylib:(CDDylibCommand *)aDylibCommand;
@end

@interface CDMachOFile : CDFile
{
    CDByteOrder byteOrder;

    NSMutableArray *loadCommands;

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

- (NSString *)filetypeDescription;
- (NSString *)flagDescription;

- (CDDylibCommand *)dylibIdentifier;

- (CDSegmentCommand *)segmentWithName:(NSString *)segmentName;
- (CDSegmentCommand *)segmentContainingAddress:(unsigned long)vmaddr;
- (const void *)pointerFromVMAddr:(uint32_t)vmaddr;
- (const void *)pointerFromVMAddr:(uint32_t)vmaddr segmentName:(NSString *)aSegmentName;
- (NSString *)stringAtAddress:(uint32_t)address;

- (const void *)machODataBytes;
- (NSUInteger)dataOffsetForAddress:(uint32_t)addr;
- (NSUInteger)dataOffsetForAddress:(uint32_t)addr segmentName:(NSString *)aSegmentName;

- (const void *)bytes;
- (const void *)bytesAtOffset:(NSUInteger)anOffset;

- (NSString *)importBaseName;

- (BOOL)hasProtectedSegments;

- (NSString *)loadCommandString:(BOOL)isVerbose;
- (NSString *)headerString:(BOOL)isVerbose;

- (NSString *)archName;

- (NSString *)description;

@end
