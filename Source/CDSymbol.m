// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDSymbol.h"

#import <mach-o/nlist.h>
#import <mach-o/loader.h>
#import "CDMachOFile.h"
#import "CDLCDylib.h"
#import "CDLCSegment.h"
#import "CDSection.h"

NSString *const ObjCClassSymbolPrefix = @"_OBJC_CLASS_$_";

@interface CDSymbol ()
@property (weak, readonly) CDMachOFile *machOFile;
@end

#pragma mark -

@implementation CDSymbol
{
    struct nlist_64 _nlist;
    BOOL _is32Bit;
    NSString *_name;
    __weak CDMachOFile *_machOFile;
}

- (id)initWithName:(NSString *)name machOFile:(CDMachOFile *)machOFile nlist32:(struct nlist)nlist32;
{
    if ((self = [super init])) {
        _is32Bit = YES;
        _name = name;
        _machOFile = machOFile;
        _nlist.n_un.n_strx = 0; // We don't use it.
        _nlist.n_type      = nlist32.n_type;
        _nlist.n_sect      = nlist32.n_sect;
        _nlist.n_desc      = nlist32.n_desc;
        _nlist.n_value     = nlist32.n_value;
    }

    return self;
}

- (id)initWithName:(NSString *)name machOFile:(CDMachOFile *)machOFile nlist64:(struct nlist_64)nlist64;
{
    if ((self = [super init])) {
        _is32Bit = NO;
        _name = name;
        _machOFile = machOFile;
        _nlist.n_un.n_strx = 0; // We don't use it.
        _nlist.n_type      = nlist64.n_type;
        _nlist.n_sect      = nlist64.n_sect;
        _nlist.n_desc      = nlist64.n_desc;
        _nlist.n_value     = nlist64.n_value;
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    NSString *valueString;

    if (self.isDefined) {
        valueString = [NSString stringWithFormat:(_is32Bit ? @"%08llx" : @"%016llx"), self.value];
    } else {
        valueString = [@" " stringByPaddingToLength:(_is32Bit ? 8 : 16) withString:@" " startingAtIndex:0];
    }

    return [NSString stringWithFormat:@"%@ %@ %@", valueString, [self shortTypeDescription], self.name];
}

#pragma mark -

+ (NSString *)classNameFromSymbolName:(NSString *)symbolName;
{
    if ([symbolName hasPrefix:ObjCClassSymbolPrefix])
        return [symbolName substringFromIndex:[ObjCClassSymbolPrefix length]];
    else
        return nil;
}

- (uint64_t)value;
{
    return _nlist.n_value;
}

- (CDSection *)section;
{
    // We might be tempted to do [[self.machOFile segmentContainingAddress:nlist.n_value] sectionContainingAddress:nlist.n_value]
    // but this does not work for __mh_dylib_header for example (n_value == 0, but it is in the __TEXT,__text section)
    NSMutableArray *sections = [NSMutableArray array];
    for (CDLCSegment *segment in self.machOFile.segments) {
        for (CDSection *section in [segment sections])
            [sections addObject:section];
    }

    // n_sect is 1-indexed (NO_SECT == 0)
    NSUInteger sectionIndex = _nlist.n_sect - 1;
    if (sectionIndex < [sections count])
        return sections[sectionIndex];
    else
        return nil;
}

- (CDLCDylib *)dylibLoadCommand;
{
    NSUInteger libraryOrdinal = GET_LIBRARY_ORDINAL(_nlist.n_desc);
    return [self.machOFile dylibLoadCommandForLibraryOrdinal:libraryOrdinal];
}

- (BOOL)isExternal;
{
    return (_nlist.n_type & N_EXT) == N_EXT;
}

- (BOOL)isPrivateExternal;
{
    return (_nlist.n_type & N_PEXT) == N_PEXT;
}

- (NSUInteger)stab;
{
    return _nlist.n_type & N_STAB;
}

- (NSUInteger)type;
{
    return _nlist.n_type & N_TYPE;
}

- (BOOL)isDefined;
{
    return self.type != N_UNDF;
}

- (BOOL)isAbsolute;
{
    return self.type == N_ABS;
}

- (BOOL)isInSection;
{
    return self.type == N_SECT;
}

- (BOOL)isPrebound;
{
    return self.type == N_PBUD;
}

- (BOOL)isIndirect;
{
    return self.type == N_INDR;
}

- (BOOL)isCommon;
{
    return !self.isDefined && self.isExternal && _nlist.n_value != 0;
}

- (BOOL)isInTextSection;
{
    CDSection *section = self.section;
    return [section.segmentName isEqualToString:@"__TEXT"] && [section.sectionName isEqualToString:@"__text"];
}

- (BOOL)isInDataSection;
{
    CDSection *section = self.section;
    return [section.segmentName isEqualToString:@"__DATA"] && [section.sectionName isEqualToString:@"__data"];
}

- (BOOL)isInBssSection;
{
    CDSection *section = self.section;
    return [section.segmentName isEqualToString:@"__DATA"] && [section.sectionName isEqualToString:@"__bss"];
}

- (NSUInteger)referenceType;
{
    return (_nlist.n_desc & REFERENCE_TYPE);
}

- (NSString *)referenceTypeName
{
    switch (self.referenceType) {
        case REFERENCE_FLAG_UNDEFINED_NON_LAZY:         return @"undefined non lazy";
        case REFERENCE_FLAG_UNDEFINED_LAZY:             return @"undefined lazy";
        case REFERENCE_FLAG_DEFINED:                    return @"defined";
        case REFERENCE_FLAG_PRIVATE_DEFINED:            return @"private defined";
        case REFERENCE_FLAG_PRIVATE_UNDEFINED_NON_LAZY: return @"private undefined non lazy";
        case REFERENCE_FLAG_PRIVATE_UNDEFINED_LAZY:     return @"private undefined lazy";
    }
    return nil;
}

- (NSComparisonResult)compare:(CDSymbol *)other;
{
    if (other.value > self.value) return NSOrderedAscending;
    if (other.value < self.value) return NSOrderedDescending;

    return NSOrderedSame;
}

- (NSComparisonResult)compareByName:(CDSymbol *)other;
{
    return [self.name compare:other.name];
}

- (NSString *)shortTypeDescription;
{
    NSString *c;

    if (self.stab)                               c = @"-";
    else if (self.isCommon)                      c = @"c";
    else if (!self.isDefined || self.isPrebound) c = @"u";
    else if (self.isAbsolute)                    c = @"a";
    else if (self.isInSection) {
        if (self.isInTextSection)                c = @"t";
        else if (self.isInDataSection)           c = @"d";
        else if (self.isInBssSection)            c = @"b";
        else                                     c = @"s";
    }
    else if (self.isIndirect)                    c = @"i";
    else                                         c = @"?";

    return self.isExternal ? [c uppercaseString] : c;
}

- (NSString *)longTypeDescription;
{
    NSString *c;

    if (self.isCommon)                           c = @"common";
    else if (!self.isDefined)                    c =  @"undefined";
    else if (self.isPrebound)                    c =  @"prebound";
    else if (self.isAbsolute)                    c =  @"absolute";
    else if (self.isInSection) {
        CDSection *section = self.section;
        if (section)                             c = [NSString stringWithFormat:@"%@,%@", section.segmentName, section.sectionName];
        else                                     c = @"?,?";
    }
    else if (self.isIndirect)                    c = @"indirect";
    else                                         c = @"?";

    return c;
}

@end
