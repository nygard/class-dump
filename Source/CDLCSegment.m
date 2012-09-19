// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDLCSegment.h"

#import "CDMachOFile.h"
#import "CDSection.h"
#include <openssl/aes.h>
#include <openssl/blowfish.h>

NSString *CDSegmentEncryptionTypeName(CDSegmentEncryptionType type)
{
    switch (type) {
        case CDSegmentEncryptionType_None:     return @"None";
        case CDSegmentEncryptionType_AES:      return @"Protected Segment Type 1 (prior to 10.6)";
        case CDSegmentEncryptionType_Blowfish: return @"Protected Segment Type 2 (10.6)";
        case CDSegmentEncryptionType_Unknown:  return @"Unknown";
    }
}

@implementation CDLCSegment
{
    NSString *_name;
    NSArray *_sections;
    
    NSMutableData *_decryptedData;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        _name = nil;
        _sections = nil;
        _decryptedData = nil;
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    NSString *extra = [self extraDescription];
    
    if (extra == nil) {
        return [NSString stringWithFormat:@"<%@:%p> name: %@",
                NSStringFromClass([self class]), self,
                self.name];
    }
    
    return [NSString stringWithFormat:@"<%@:%p> name: %@, %@",
            NSStringFromClass([self class]), self,
            self.name, extra];
}

- (NSString *)extraDescription;
{
    // Implement in subclasses
    return nil;
}

#pragma mark -

- (NSUInteger)vmaddr;
{
    // Implement in subclasses.
    return 0;
}

- (NSUInteger)fileoff;
{
    // Implement in subclasses.
    return 0;
}

- (NSUInteger)filesize;
{
    // Implement in subclasses.
    return 0;
}

- (vm_prot_t)initprot;
{
    // Implement in subclsses.
    return 0;
}

- (uint32_t)flags;
{
    // Implement in subclsses.
    return 0;
}

- (BOOL)isProtected;
{
    return (self.flags & SG_PROTECTED_VERSION_1) == SG_PROTECTED_VERSION_1;
}

- (CDSegmentEncryptionType)encryptionType;
{
    //NSLog(@"%s, isProtected? %u, filesize: %lu, fileoff: %lu", __cmd, [self isProtected], [self filesize], [self fileoff]);
    if (self.isProtected) {
        if (self.filesize <= 3 * PAGE_SIZE) {
            // First three pages aren't encrypted, so we can't tell.  Let's pretent it's something we can decrypt.
            return CDSegmentEncryptionType_AES;
        } else {
            const void *src = (uint8_t *)[self.machOFile.data bytes] + self.fileoff + 3 * PAGE_SIZE;

            uint32_t magic = OSReadLittleInt32(src, 0);
            //NSLog(@"%s, magic= 0x%08x", __cmd, magic);
            switch (magic) {
                case CDSegmentProtectedMagic_None:     return CDSegmentEncryptionType_None;
                case CDSegmentProtectedMagic_AES:      return CDSegmentEncryptionType_AES;
                case CDSegmentProtectedMagic_Blowfish: return CDSegmentEncryptionType_Blowfish;
            }

            return CDSegmentEncryptionType_Unknown;
        }
    }

    return CDSegmentEncryptionType_None;
}

- (BOOL)canDecrypt;
{
    CDSegmentEncryptionType encryptionType = self.encryptionType;

    return (encryptionType == CDSegmentEncryptionType_None)
        || (encryptionType == CDSegmentEncryptionType_AES)
        || (encryptionType == CDSegmentEncryptionType_Blowfish);
}

- (NSString *)flagDescription;
{
    NSMutableArray *setFlags = [NSMutableArray array];
    uint32_t flags = self.flags;
    if (flags & SG_HIGHVM)              [setFlags addObject:@"HIGHVM"];
    if (flags & SG_FVMLIB)              [setFlags addObject:@"FVMLIB"];
    if (flags & SG_NORELOC)             [setFlags addObject:@"NORELOC"];
    if (flags & SG_PROTECTED_VERSION_1) [setFlags addObject:@"PROTECTED_VERSION_1"];

    if ([setFlags count] == 0)
        return @"(none)";

    return [setFlags componentsJoinedByString:@" "];
}

- (BOOL)containsAddress:(NSUInteger)address;
{
    // Implement in subclasses
    return NO;
}

- (CDSection *)sectionContainingAddress:(NSUInteger)address;
{
    for (CDSection *section in self.sections) {
        if ([section containsAddress:address])
            return section;
    }

    return nil;
}

- (CDSection *)sectionWithName:(NSString *)name;
{
    for (CDSection *section in self.sections) {
        if ([[section sectionName] isEqual:name])
            return section;
    }

    return nil;
}

- (NSUInteger)fileOffsetForAddress:(NSUInteger)address;
{
    return [[self sectionContainingAddress:address] fileOffsetForAddress:address];
}

- (NSUInteger)segmentOffsetForAddress:(NSUInteger)address;
{
    return [self fileOffsetForAddress:address] - self.fileoff;
}

- (void)appendToString:(NSMutableString *)resultString verbose:(BOOL)isVerbose;
{
    [super appendToString:resultString verbose:isVerbose];
#if 0
    [resultString appendFormat:@"  segname %@\n",     self.name];
    [resultString appendFormat:@"   vmaddr 0x%08x\n", segmentCommand.vmaddr];
    [resultString appendFormat:@"   vmsize 0x%08x\n", segmentCommand.vmsize];
    [resultString appendFormat:@"  fileoff %d\n",     segmentCommand.fileoff];
    [resultString appendFormat:@" filesize %d\n",     segmentCommand.filesize];
    [resultString appendFormat:@"  maxprot 0x%08x\n", segmentCommand.maxprot];
    [resultString appendFormat:@" initprot 0x%08x\n", segmentCommand.initprot];
    [resultString appendFormat:@"   nsects %d\n",     segmentCommand.nsects];

    if (isVerbose)
        [resultString appendFormat:@"    flags %@\n", [self flagDescription]];
    else
        [resultString appendFormat:@"    flags 0x%x\n", segmentCommand.flags];
#endif
    // Implement in subclasses
}

- (void)writeSectionData;
{
    [self.sections enumerateObjectsUsingBlock:^(CDSection *section, NSUInteger index, BOOL *stop){
        [[section data] writeToFile:[NSString stringWithFormat:@"/tmp/%02ld-%@", index, section.sectionName] atomically:NO];
    }];
}

- (NSData *)decryptedData;
{
    if (self.isProtected == NO)
        return nil;

    if (_decryptedData == nil) {
        //NSLog(@"filesize: %08x, pagesize: %04x", [self filesize], PAGE_SIZE);
        NSParameterAssert((self.filesize % PAGE_SIZE) == 0);
        _decryptedData = [[NSMutableData alloc] initWithLength:self.filesize];

        const uint8_t *src = (uint8_t *)[self.machOFile.data bytes] + self.fileoff;
        uint8_t *dest = [_decryptedData mutableBytes];

        if (self.filesize <= PAGE_SIZE * 3) {
            memcpy(dest, src, [self filesize]);
        } else {
            uint8_t keyData[64] = { 0x6f, 0x75, 0x72, 0x68, 0x61, 0x72, 0x64, 0x77, 0x6f, 0x72, 0x6b, 0x62, 0x79, 0x74, 0x68, 0x65,
                                    0x73, 0x65, 0x77, 0x6f, 0x72, 0x64, 0x73, 0x67, 0x75, 0x61, 0x72, 0x64, 0x65, 0x64, 0x70, 0x6c,
                                    0x65, 0x61, 0x73, 0x65, 0x64, 0x6f, 0x6e, 0x74, 0x73, 0x74, 0x65, 0x61, 0x6c, 0x28, 0x63, 0x29,
                                    0x41, 0x70, 0x70, 0x6c, 0x65, 0x43, 0x6f, 0x6d, 0x70, 0x75, 0x74, 0x65, 0x72, 0x49, 0x6e, 0x63, };

            // First three pages are encrypted, just copy
            memcpy(dest, src, PAGE_SIZE * 3);
            src += PAGE_SIZE * 3;
            dest += PAGE_SIZE * 3;
            NSUInteger count = (self.filesize / PAGE_SIZE) - 3;
            
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

            uint32_t magic = OSReadLittleInt32(src, 0);
            if (magic == CDSegmentProtectedMagic_None) {
                memcpy(dest, src, [self filesize] - PAGE_SIZE * 3);
            } else if (magic == CDSegmentProtectedMagic_Blowfish) {
                // 10.6 decryption
                unsigned char ivec[8];
                BF_KEY key;

                BF_set_key(&key, 64, keyData);

                for (NSUInteger index = 0; index < count; index++) {
                    memset(ivec, 0, 8);
                    BF_cbc_encrypt(src, dest, PAGE_SIZE, &key, ivec, BF_DECRYPT);

                    src += PAGE_SIZE;
                    dest += PAGE_SIZE;
                }
            } else if (magic == CDSegmentProtectedMagic_AES) {
                AES_KEY key1, key2;

                // 10.5 decryption

                AES_set_decrypt_key(keyData, 256, &key1);
                AES_set_decrypt_key(keyData + 32, 256, &key2);

                for (NSUInteger index = 0; index < count; index++) {
                    unsigned char iv1[AES_BLOCK_SIZE];
                    unsigned char iv2[AES_BLOCK_SIZE];

                    //NSLog(@"src = %08x, encrypted", src);
                    memset(iv1, 0, AES_BLOCK_SIZE);
                    memset(iv2, 0, AES_BLOCK_SIZE);
                    AES_cbc_encrypt(src, dest, PAGE_SIZE / 2, &key1, iv1, AES_DECRYPT);
                    AES_cbc_encrypt(src + PAGE_SIZE / 2, dest + PAGE_SIZE / 2, PAGE_SIZE / 2, &key2, iv2, AES_DECRYPT);

                    src += PAGE_SIZE;
                    dest += PAGE_SIZE;
                }
            } else {
                NSLog(@"Unknown encryption type: 0x%08x", magic);
                exit(99);
            }
            
#pragma clang diagnostic pop
        }
    }

    return _decryptedData;
}

@end

