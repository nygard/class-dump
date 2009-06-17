// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2007  Steve Nygard

#import <Foundation/NSObject.h>

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

@interface CDMachOFile : NSObject
{
    //NSString *filename;
    NSData *data;

    uint32_t magic; // This is read in and stored in little endian order.
    cpu_type_t cputype;
    cpu_subtype_t cpusubtype;
    uint32_t filetype;
    uint32_t flags; // header flags

    CDByteOrder byteOrder;

    //struct mach_header header;

    NSMutableArray *loadCommands;

    struct {
        unsigned int uses64BitABI:1;
    } _flags;

    id nonretainedDelegate;
}

extern NSString *CDNameForCPUType(cpu_type_t cputype, cpu_subtype_t cpusubtype);

+ (id)machOFileWithFilename:(NSString *)aFilename;

- (id)initWithData:(NSData *)_data;
- (void)dealloc;

- (NSString *)filename;

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

- (void)process;
- (NSArray *)_processLoadCommands;

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
