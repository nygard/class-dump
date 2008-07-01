// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2007  Steve Nygard

#import <Foundation/NSObject.h>

#ifdef __BIG_ENDIAN__
#define CD_THIS_BYTE_ORDER NX_BigEndian
#else
#define CD_THIS_BYTE_ORDER NX_LittleEndian
#endif

@class NSArray, NSData, NSMutableArray;
@class CDFatArch, CDMachOFile;

@interface CDFatFile : NSObject
{
    NSMutableArray *arches;
}

- (id)initWithData:(NSData *)data;
- (void)dealloc;

- (CDFatArch *)fatArchWithName:(NSString *)archName;
- (CDFatArch *)_fatArchWithName:(NSString *)archName;
- (CDFatArch *)localArchitecture;

- (NSString *)description;

- (NSArray *)archNames;

@end
