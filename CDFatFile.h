//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import <Foundation/NSObject.h>
#include <mach-o/fat.h>

#ifdef __BIG_ENDIAN__
#define CD_FAT_MAGIC FAT_MAGIC
#else
#define CD_FAT_MAGIC FAT_CIGAM
#endif

@class NSData, NSMutableArray;
@class CDFatArch, CDMachOFile;

@interface CDFatFile : NSObject
{
    NSString *filename;
    NSData *data;
    const struct fat_header *header;
    NSMutableArray *arches;
}

+ (id)machOFileWithFilename:(NSString *)aFilename preferredCPUType:(cpu_type_t)preferredCPUType;

- (id)initWithFilename:(NSString *)aFilename;
- (void)dealloc;

- (void)_processFatArches;

- (NSString *)filename;

- (unsigned int)fatCount;

- (CDFatArch *)fatArchWithPreferredCPUType:(cpu_type_t)preferredCPUType;
- (CDFatArch *)fatArchWithCPUType:(cpu_type_t)aCPUType;

- (NSString *)description;

@end
