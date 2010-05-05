// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDLoadCommand.h"
#include <mach-o/loader.h>

@class CDSection;

#define CDSegmentProtectedMagicTypeNone 0
#define CDSegmentProtectedMagicType1 0xc2286295
#define CDSegmentProtectedMagicType2 0x2e69cf40

enum {
    CDSegmentEncryptionTypeNone = 0,
    CDSegmentEncryptionType1 = 1, // Prior to 10.5 (AES)
    CDSegmentEncryptionType2 = 2, // 10.6 (Blowfish)
    CDSegmentEncryptionTypeUnknown
};
typedef NSUInteger CDSegmentEncryptionType;

extern NSString *CDSegmentEncryptionTypeName(CDSegmentEncryptionType type);

@interface CDLCSegment : CDLoadCommand
{
    NSString *name;
    NSMutableArray *sections;

    NSMutableData *decryptedData;
}

- (id)initWithDataCursor:(CDDataCursor *)cursor machOFile:(CDMachOFile *)aMachOFile;
- (void)dealloc;

- (NSString *)name;
- (void)setName:(NSString *)newName;

- (NSArray *)sections;

- (NSUInteger)vmaddr;
- (NSUInteger)fileoff;
- (NSUInteger)filesize;
- (vm_prot_t)initprot;
- (uint32_t)flags;
- (BOOL)isProtected;

- (CDSegmentEncryptionType)encryptionType;
- (BOOL)canDecrypt;

- (NSString *)flagDescription;
- (NSString *)extraDescription;

- (BOOL)containsAddress:(NSUInteger)address;
- (CDSection *)sectionContainingAddress:(NSUInteger)address;
- (CDSection *)sectionWithName:(NSString *)aName;
- (NSUInteger)fileOffsetForAddress:(NSUInteger)address;
- (NSUInteger)segmentOffsetForAddress:(NSUInteger)address;

- (void)appendToString:(NSMutableString *)resultString verbose:(BOOL)isVerbose;

- (void)writeSectionData;

- (NSData *)decryptedData;

@end
