// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2011 Steve Nygard.

#import "CDLoadCommand.h"

@class CDSection;

#define CDSegmentProtectedMagic_None     0
#define CDSegmentProtectedMagic_AES      0xc2286295
#define CDSegmentProtectedMagic_Blowfish 0x2e69cf40

enum {
    CDSegmentEncryptionType_None = 0,
    CDSegmentEncryptionType_AES = 1, // Prior to 10.5 (AES)
    CDSegmentEncryptionType_Blowfish = 2, // 10.6 (Blowfish)
    CDSegmentEncryptionType_Unknown
};
typedef NSUInteger CDSegmentEncryptionType;

extern NSString *CDSegmentEncryptionTypeName(CDSegmentEncryptionType type);

@interface CDLCSegment : CDLoadCommand
{
    NSString *name;
    NSArray *sections;

    NSMutableData *decryptedData;
}

@property (retain) NSString *name;

@property (readonly) NSArray *sections;

@property (readonly) NSUInteger vmaddr;
@property (readonly) NSUInteger fileoff;
@property (readonly) NSUInteger filesize;
@property (readonly) vm_prot_t initprot;
@property (readonly) uint32_t flags;
@property (readonly) BOOL isProtected;

@property (readonly) CDSegmentEncryptionType encryptionType;
@property (readonly) BOOL canDecrypt;

- (NSString *)flagDescription;

- (BOOL)containsAddress:(NSUInteger)address;
- (CDSection *)sectionContainingAddress:(NSUInteger)address;
- (CDSection *)sectionWithName:(NSString *)aName;
- (NSUInteger)fileOffsetForAddress:(NSUInteger)address;
- (NSUInteger)segmentOffsetForAddress:(NSUInteger)address;

- (void)writeSectionData;

- (NSData *)decryptedData;

@end
