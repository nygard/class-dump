// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import <Foundation/Foundation.h>

#import "CDFile.h" // For CDArch

@class CDDataCursor;
@class CDFatFile, CDMachOFile;

@interface CDFatArch : NSObject

- (id)initWithDataCursor:(CDDataCursor *)cursor;

- (NSString *)description;

@property (readonly) cpu_type_t cpuType;
@property (readonly) cpu_type_t maskedCPUType;
@property (readonly) cpu_subtype_t cpuSubtype;
@property (readonly) uint32_t offset;
@property (readonly) uint32_t size;
@property (readonly) uint32_t align;

@property (readonly) BOOL uses64BitABI;

@property (assign) CDFatFile *fatFile;

@property (readonly) CDArch arch;
@property (readonly) NSString *archName;

@property (readonly) CDMachOFile *machOFile;
@property (readonly) NSData *machOData;

@end
