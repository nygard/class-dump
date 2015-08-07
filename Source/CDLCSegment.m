// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDLCSegment.h"

#import "CDMachOFile.h"
#import "CDSection.h"

#include <CommonCrypto/CommonCrypto.h>

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
    struct segment_command_64 _segmentCommand; // 64-bit, also holding 32-bit
    
    NSString *_name;
    NSArray *_sections;
    
    NSMutableData *_decryptedData;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        _segmentCommand.cmd     = [cursor readInt32];
        _segmentCommand.cmdsize = [cursor readInt32];
        
        _name = [cursor readStringOfLength:16 encoding:NSASCIIStringEncoding];
        memcpy(_segmentCommand.segname, [_name UTF8String], sizeof(_segmentCommand.segname));
        _segmentCommand.vmaddr   = [cursor readPtr];
        _segmentCommand.vmsize   = [cursor readPtr];
        _segmentCommand.fileoff  = [cursor readPtr];
        _segmentCommand.filesize = [cursor readPtr];
        _segmentCommand.maxprot  = [cursor readInt32];
        _segmentCommand.initprot = [cursor readInt32];
        _segmentCommand.nsects   = [cursor readInt32];
        _segmentCommand.flags    = [cursor readInt32];
        
        NSMutableArray *sections = [[NSMutableArray alloc] init];
        for (NSUInteger index = 0; index < _segmentCommand.nsects; index++) {
            CDSection *section = [[CDSection alloc] initWithDataCursor:cursor segment:self];
            [sections addObject:section];
        }
        _sections = [sections copy];
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)extraDescription;
{
    int padding = (int)self.machOFile.ptrSize * 2;
    return [NSString stringWithFormat:@"vmaddr: 0x%0*llx - 0x%0*llx [0x%0*llx], offset: %lld, flags: 0x%x (%@), nsects: %d, sections: %@",
            padding, _segmentCommand.vmaddr, padding, _segmentCommand.vmaddr + _segmentCommand.vmsize - 1, padding, _segmentCommand.vmsize,
            _segmentCommand.fileoff, self.flags, [self flagDescription], _segmentCommand.nsects, self.sections.count > 0 ? self.sections : @"N/A"];
}

#pragma mark -

- (uint32_t)cmd;
{
    return _segmentCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return _segmentCommand.cmdsize;
}

- (NSUInteger)vmaddr;
{
    return _segmentCommand.vmaddr;
}

- (NSUInteger)fileoff;
{
    return _segmentCommand.fileoff;
}

- (NSUInteger)filesize;
{
    return _segmentCommand.filesize;
}

- (vm_prot_t)initprot;
{
    return _segmentCommand.initprot;
}

- (uint32_t)flags;
{
    return _segmentCommand.flags;
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
        return @"none";

    return [setFlags componentsJoinedByString:@" "];
}

- (BOOL)containsAddress:(NSUInteger)address;
{
    return (address >= _segmentCommand.vmaddr) && (address < _segmentCommand.vmaddr + _segmentCommand.vmsize);
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
    int padding = (int)self.machOFile.ptrSize * 2;
    [resultString appendFormat:@"  segname %@\n",       self.name];
    [resultString appendFormat:@"   vmaddr 0x%0*llx\n", padding, _segmentCommand.vmaddr];
    [resultString appendFormat:@"   vmsize 0x%0*llx\n", padding, _segmentCommand.vmsize];
    [resultString appendFormat:@"  fileoff %lld\n",     _segmentCommand.fileoff];
    [resultString appendFormat:@" filesize %lld\n",     _segmentCommand.filesize];
    [resultString appendFormat:@"  maxprot 0x%08x\n",   _segmentCommand.maxprot];
    [resultString appendFormat:@" initprot 0x%08x\n",   _segmentCommand.initprot];
    [resultString appendFormat:@"   nsects %d\n",       _segmentCommand.nsects];

    if (isVerbose)
        [resultString appendFormat:@"    flags %@\n", [self flagDescription]];
    else
        [resultString appendFormat:@"    flags 0x%x\n", _segmentCommand.flags];
#endif
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

            // First three pages aren't encrypted, just copy
            memcpy(dest, src, PAGE_SIZE * 3);
            src += PAGE_SIZE * 3;
            dest += PAGE_SIZE * 3;
            NSUInteger count = (self.filesize / PAGE_SIZE) - 3;
            
            uint32_t magic = OSReadLittleInt32(src, 0);
            if (magic == CDSegmentProtectedMagic_None) {
                memcpy(dest, src, [self filesize] - PAGE_SIZE * 3);
            } else if (magic == CDSegmentProtectedMagic_Blowfish) {
                // 10.6 decryption
                CCCryptorRef cryptor;
                CCCryptorStatus status = CCCryptorCreate(kCCDecrypt, kCCAlgorithmBlowfish, 0, keyData, sizeof(keyData), NULL, &cryptor);
                NSParameterAssert(status == kCCSuccess);
                for (NSUInteger index = 0; index < count; index++) {
                    status = CCCryptorReset(cryptor, NULL);
                    NSParameterAssert(status == kCCSuccess);

                    size_t moved;
                    status = CCCryptorUpdate(cryptor, src, PAGE_SIZE, dest, PAGE_SIZE, &moved);
                    NSParameterAssert(status == kCCSuccess);
                    NSParameterAssert(moved == PAGE_SIZE);

                    src += PAGE_SIZE;
                    dest += PAGE_SIZE;
                }
                CCCryptorRelease(cryptor);
            } else if (magic == CDSegmentProtectedMagic_AES) {
                // 10.5 decryption
                CCCryptorRef cryptor1, cryptor2;
                CCCryptorStatus status;

                status = CCCryptorCreate(kCCDecrypt, kCCAlgorithmAES, 0, keyData,      32, NULL, &cryptor1);
                NSParameterAssert(status == kCCSuccess);

                status = CCCryptorCreate(kCCDecrypt, kCCAlgorithmAES, 0, keyData + 32, 32, NULL, &cryptor2);
                NSParameterAssert(status == kCCSuccess);

                size_t halfPageSize = PAGE_SIZE / 2;

                for (NSUInteger index = 0; index < count; index++) {
                    status = CCCryptorReset(cryptor1, NULL);
                    NSParameterAssert(status == kCCSuccess);

                    status = CCCryptorReset(cryptor2, NULL);
                    NSParameterAssert(status == kCCSuccess);

                    size_t moved;

                    status = CCCryptorUpdate(cryptor1, src,                halfPageSize, dest,                halfPageSize, &moved);
                    NSParameterAssert(status == kCCSuccess);
                    NSParameterAssert(moved == halfPageSize);

                    status = CCCryptorUpdate(cryptor2, src + halfPageSize, halfPageSize, dest + halfPageSize, halfPageSize, &moved);
                    NSParameterAssert(status == kCCSuccess);
                    NSParameterAssert(moved == halfPageSize);

                    src += PAGE_SIZE;
                    dest += PAGE_SIZE;
                }

                CCCryptorRelease(cryptor1);
                CCCryptorRelease(cryptor2);
            } else {
                NSLog(@"Unknown encryption type: 0x%08x", magic);
                exit(99);
            }
        }
    }

    return _decryptedData;
}

@end

