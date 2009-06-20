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
    //NSString *filename;
    NSData *data;

    struct mach_header header; // header.magic is read in and stored in little endian order.(?)
    CDByteOrder byteOrder;

    NSMutableArray *loadCommands;

    struct {
        unsigned int uses64BitABI:1;
    } _flags;

    id nonretainedDelegate;
}

+ (id)machOFileWithFilename:(NSString *)aFilename;

- (id)initWithData:(NSData *)_data;
- (void)dealloc;

- (NSString *)bestMatchForLocalArch;
- (CDMachOFile *)machOFileWithArchName:(NSString *)name;

- (NSString *)filename;

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

- (void)process;

- (cpu_type_t)cpuType;
- (cpu_subtype_t)cpuSubtype;
- (uint32_t)filetype;
- (uint32_t)flags;

- (NSArray *)loadCommands;

- (NSString *)filetypeDescription;
- (NSString *)flagDescription;
- (NSString *)description;

- (CDDylibCommand *)dylibIdentifier;

- (CDSegmentCommand *)segmentWithName:(NSString *)segmentName;
- (CDSegmentCommand *)segmentContainingAddress:(unsigned long)vmaddr;
- (const void *)pointerFromVMAddr:(unsigned long)vmaddr;
- (const void *)pointerFromVMAddr:(unsigned long)vmaddr segmentName:(NSString *)aSegmentName;
- (NSString *)stringFromVMAddr:(unsigned long)vmaddr;

- (const void *)bytes;
- (const void *)bytesAtOffset:(unsigned long)offset;

- (NSString *)importBaseName;

- (BOOL)hasProtectedSegments;

- (NSString *)loadCommandString:(BOOL)isVerbose;
- (NSString *)headerString:(BOOL)isVerbose;

- (NSString *)archName;

// To remove:
- (BOOL)hasDifferentByteOrder;

@end
