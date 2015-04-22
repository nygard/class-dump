// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDFile.h" // For CDArch

@class CDDataCursor;
@class CDFatFile, CDMachOFile;

@interface CDFatArch : NSObject

- (id)initWithMachOFile:(CDMachOFile *)machOFile;
- (id)initWithDataCursor:(CDDataCursor *)cursor;

@property (assign) cpu_type_t cputype;
@property (assign) cpu_subtype_t cpusubtype;
@property (assign) uint32_t offset;
@property (assign) uint32_t size;
@property (assign) uint32_t align;

@property (nonatomic, readonly) cpu_type_t maskedCPUType;
@property (nonatomic, readonly) cpu_subtype_t maskedCPUSubtype;
@property (nonatomic, readonly) BOOL uses64BitABI;
@property (nonatomic, readonly) BOOL uses64BitLibraries;

@property (weak) CDFatFile *fatFile;

@property (nonatomic, readonly) CDArch arch;
@property (nonatomic, readonly) NSString *archName;

@property (nonatomic, readonly) CDMachOFile *machOFile;

@end
