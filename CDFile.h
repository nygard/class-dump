// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2009 Steve Nygard.  All rights reserved.

#import <Foundation/Foundation.h>

#include <mach-o/arch.h>
#include <mach-o/loader.h>
#include <mach-o/fat.h>
#include <mach-o/swap.h>

@class CDMachOFile;

extern NSString *CDNameForCPUType(cpu_type_t cputype, cpu_subtype_t cpusubtype);

@interface CDFile : NSObject
{
    NSString *filename;
    NSData *data;
    NSUInteger offset; // Or perhaps dataOffset, archiveOffset
}

// Returns CDFatFile, CDMachO32File, or CDMachO64File.
+ (id)fileWithData:(NSData *)someData;
+ (id)fileWithData:(NSData *)someData offset:(NSUInteger)anOffset;

- (id)initWithData:(NSData *)someData offset:(NSUInteger)anOffset;
- (void)dealloc;

- (NSString *)filename;
- (void)setFilename:(NSString *)newName;

- (NSData *)data;

- (NSUInteger)offset;
- (void)setOffset:(NSUInteger)newOffset;

- (NSString *)bestMatchForLocalArch;
- (CDMachOFile *)machOFileWithArchName:(NSString *)name;

@end
