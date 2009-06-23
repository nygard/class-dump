// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import "CDFile.h"

#ifdef __BIG_ENDIAN__
#define CD_THIS_BYTE_ORDER NX_BigEndian
#else
#define CD_THIS_BYTE_ORDER NX_LittleEndian
#endif

@class NSArray, NSData, NSMutableArray;
@class CDFatArch, CDMachOFile;

@interface CDFatFile : CDFile
{
    NSMutableArray *arches;
}

- (id)initWithData:(NSData *)someData offset:(NSUInteger)anOffset;
- (void)dealloc;

- (NSString *)bestMatchForLocalArch;
- (CDMachOFile *)machOFileWithArchName:(NSString *)name;

- (NSString *)description;

- (NSArray *)archNames;

@end
