// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDSymbol.h"

#import <mach-o/nlist.h>
#import <mach-o/loader.h>
#import "CDMachOFile.h"
#import "CDLCDylib.h"
#import "CDLCSegment.h"
#import "CDSection.h"

NSString *const ObjCClassSymbolPrefix = @"_OBJC_CLASS_$_";

@implementation CDSymbol

- (id)initWithName:(NSString *)aName machOFile:(CDMachOFile *)aMachOFile nlist32:(struct nlist)nlist32;
{
    if ([super init] == nil)
        return nil;

    is32Bit = YES;
    name = [aName retain];
    nonretained_machOFile = aMachOFile;
    nlist.n_un.n_strx = 0; // We don't use it.
    nlist.n_type = nlist32.n_type;
    nlist.n_sect = nlist32.n_sect;
    nlist.n_desc = nlist32.n_desc;
    nlist.n_value = nlist32.n_value;

    return self;
}

- (id)initWithName:(NSString *)aName machOFile:(CDMachOFile *)aMachOFile nlist64:(struct nlist_64)nlist64;
{
    if ([super init] == nil)
        return nil;

    is32Bit = NO;
    name = [aName retain];
    nonretained_machOFile = aMachOFile;
    nlist.n_un.n_strx = 0; // We don't use it.
    nlist.n_type = nlist64.n_type;
    nlist.n_sect = nlist64.n_sect;
    nlist.n_desc = nlist64.n_desc;
    nlist.n_value = nlist64.n_value;

    return self;
}

- (void)dealloc;
{
    [name release];

    [super dealloc];
}

- (uint64_t)value;
{
    return nlist.n_value;
}

- (NSString *)name;
{
    return name;
}

- (CDSection *)section
{
    // We might be tempted to do [[nonretained_machOFile segmentContainingAddress:nlist.n_value] sectionContainingAddress:nlist.n_value]
    // but this does not work for __mh_dylib_header for example (n_value == 0, but it is in the __TEXT,__text section)
    NSMutableArray *sections = [NSMutableArray array];
    for (CDLCSegment *segment in [nonretained_machOFile segments]) {
        for (CDSection *section in [segment sections])
            [sections addObject:section];
    }

    // n_sect is 1-indexed (NO_SECT == 0)
    NSUInteger sectionIndex = nlist.n_sect - 1;
    if (sectionIndex < [sections count])
        return [sections objectAtIndex:sectionIndex];
    else
        return nil;
}

- (CDLCDylib *)dylibLoadCommand;
{
    NSUInteger libraryOrdinal = GET_LIBRARY_ORDINAL(nlist.n_desc);
    NSArray *dylibLoadCommands = [nonretained_machOFile dylibLoadCommands];

    if (libraryOrdinal < [dylibLoadCommands count])
        return [dylibLoadCommands objectAtIndex:libraryOrdinal];
    else
        return nil;
}

- (BOOL)isExternal;
{
    return (nlist.n_type & N_EXT) == N_EXT;
}

- (BOOL)isPrivateExternal;
{
    return (nlist.n_type & N_PEXT) == N_PEXT;
}

- (NSUInteger)stab;
{
    return nlist.n_type & N_STAB;
}

- (NSUInteger)type;
{
    return nlist.n_type & N_TYPE;
}

- (BOOL)isUndefined;
{
    return [self type] == N_UNDF;
}

- (BOOL)isAbsolte;
{
    return [self type] == N_ABS;
}

- (BOOL)isInSection;
{
    return [self type] == N_SECT;
}

- (BOOL)isPrebound;
{
    return [self type] == N_PBUD;
}

- (BOOL)isIndirect;
{
    return [self type] == N_INDR;
}

- (BOOL)isCommon;
{
    return [self isUndefined] && [self isExternal] && nlist.n_value != 0;
}

- (BOOL)isInTextSection;
{
    CDSection *section = [self section];
    return [[section segmentName] isEqualToString:@"__TEXT"] && [[section sectionName] isEqualToString:@"__text"];
}

- (BOOL)isInDataSection;
{
    CDSection *section = [self section];
    return [[section segmentName] isEqualToString:@"__DATA"] && [[section sectionName] isEqualToString:@"__data"];
}

- (BOOL)isInBssSection;
{
    CDSection *section = [self section];
    return [[section segmentName] isEqualToString:@"__DATA"] && [[section sectionName] isEqualToString:@"__bss"];
}

- (NSUInteger)referenceType;
{
    return (nlist.n_desc & REFERENCE_TYPE);
}

- (NSString *)referenceTypeName
{
    switch ([self referenceType]) {
      case REFERENCE_FLAG_UNDEFINED_NON_LAZY: return @"undefined non lazy";
      case REFERENCE_FLAG_UNDEFINED_LAZY: return @"undefined lazy";
      case REFERENCE_FLAG_DEFINED: return @"defined";
      case REFERENCE_FLAG_PRIVATE_DEFINED: return @"private defined";
      case REFERENCE_FLAG_PRIVATE_UNDEFINED_NON_LAZY: return @"private undefined non lazy";
      case REFERENCE_FLAG_PRIVATE_UNDEFINED_LAZY: return @"private undefined lazy";
    }
    return nil;
}

- (NSComparisonResult)compare:(CDSymbol *)aSymbol;
{
    if ([aSymbol value] > [self value])
        return NSOrderedAscending;
    else if ([aSymbol value] < [self value])
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

- (NSComparisonResult)nameCompare:(CDSymbol *)aSymbol;
{
    return [[self name] compare:[aSymbol name]];
}

- (NSString *)shortTypeDescription;
{
    NSString *c = nil;

    if ([self stab])
        c = @"-";
    else if ([self isCommon])
        c = @"c";
    else if ([self isUndefined] || [self isPrebound])
        c =  @"u";
    else if ([self isAbsolte])
        c =  @"a";
    else if ([self isInSection]) {
        if ([self isInTextSection])
            c = @"t";
        else if ([self isInDataSection])
            c = @"d";
        else if ([self isInBssSection])
            c = @"b";
        else
            c = @"s";
    }
    else if ([self isIndirect])
        c = @"i";
    else
        c = @"?";

    return [self isExternal] ? [c uppercaseString] : c;
}

- (NSString *)longTypeDescription;
{
    NSString *c = nil;

    if ([self isCommon])
        c = @"common";
    else if ([self isUndefined])
        c =  @"undefined";
    else if ([self isPrebound])
        c =  @"prebound";
    else if ([self isAbsolte])
        c =  @"absolute";
    else if ([self isInSection]) {
        CDSection *section = [self section];
        if (section)
            c = [NSString stringWithFormat:@"%@,%@", [section segmentName], [section sectionName]];
        else
            c = @"?,?";
    }
    else if ([self isIndirect])
        c = @"indirect";
    else
        c = @"?";

    return c;
}

- (NSString *)description;
{
    NSString *valueFormat = [NSString stringWithFormat:@"%%0%ullx", is32Bit ? 8 : 16];
    NSString *valuePad = is32Bit ? @"        " : @"                ";
    NSString *valueString = [self isUndefined] ? valuePad : [NSString stringWithFormat:valueFormat, [self value]];
    NSString *dylibName = [[[[[self dylibLoadCommand] path] lastPathComponent] componentsSeparatedByString:@"."] objectAtIndex:0];
    NSString *fromString = [self isUndefined] ? [NSString stringWithFormat:@" (from %@)", dylibName] : @"";
    return [NSString stringWithFormat:@"%@ %@ %@", valueString, [self shortTypeDescription], name];
    return [NSString stringWithFormat:@"%@ (%@) %@ %@%@", valueString, [self longTypeDescription], [self isExternal] ? @"external" : @"non-external", name, fromString];
    return [NSString stringWithFormat:[valueFormat stringByAppendingString:@" %02x %02x %04x - %@"],
            nlist.n_value, nlist.n_type, nlist.n_sect, nlist.n_desc, name];
}

@end
