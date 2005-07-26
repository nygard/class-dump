//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import <Foundation/NSObject.h>

#include <mach/machine.h> // For cpu_type_t, cpu_subtype_t

@class NSData;
@class CDSegmentCommand;

#if 0
@interface CDFatMachOFile : NSObject
{
}

@end
#endif

@class NSArray;
@class CDDylibCommand, CDMachOFile;

@protocol CDMachOFileDelegate
- (void)machOFile:(CDMachOFile *)aMachOFile loadDylib:(CDDylibCommand *)aDylibCommand;
@end

@interface CDMachOFile : NSObject
{
    NSString *filename;
    NSData *data;
    unsigned int archiveOffset;
    const struct mach_header *header;
    NSArray *loadCommands;

    id nonretainedDelegate;
}

- (id)initWithFilename:(NSString *)aFilename;
- (id)initWithFilename:(NSString *)aFilename archiveOffset:(unsigned int)anArchiveOffset;
- (void)dealloc;

- (NSString *)filename;

- (unsigned int)archiveOffset;

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

- (void)process;
- (NSArray *)_processLoadCommands;

- (NSArray *)loadCommands;
- (cpu_type_t)cpuType;
- (cpu_subtype_t)cpuSubtype;
- (unsigned long)filetype;
- (unsigned long)flags;

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

@end
