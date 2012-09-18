// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import <Foundation/Foundation.h>

#import "CDFile.h" // For CDArch

@class CDDataCursor;
@class CDFatFile, CDMachOFile;

@interface CDFatArch : NSObject

- (id)initWithMachOFile:(CDMachOFile *)machOFile;
- (id)initWithDataCursor:(CDDataCursor *)cursor;

@property (nonatomic, readonly) cpu_type_t cpuType;
@property (nonatomic, readonly) cpu_type_t maskedCPUType;
@property (nonatomic, readonly) cpu_subtype_t cpuSubtype;
@property (nonatomic, readonly) uint32_t offset;
@property (nonatomic, readonly) uint32_t size;
@property (nonatomic, readonly) uint32_t align;

@property (nonatomic, readonly) BOOL uses64BitABI;

@property (weak) CDFatFile *fatFile;

@property (nonatomic, readonly) CDArch arch;
@property (nonatomic, readonly) NSString *archName;

@property (nonatomic, readonly) CDMachOFile *machOFile;

@end
