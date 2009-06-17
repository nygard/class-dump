//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2007  Steve Nygard

#import "CDMachOFile.h"

#import <Foundation/Foundation.h>
#include <mach-o/arch.h>
#include <mach-o/loader.h>
#include <mach-o/fat.h>
#include <mach-o/swap.h>

#import "CDDataCursor.h"
#import "CDDylibCommand.h"
#import "CDFatFile.h"
#import "CDLoadCommand.h"
#import "CDSegmentCommand.h"

NSString *CDMagicNumberString(uint32_t magic)
{
    switch (magic) {
      case MH_MAGIC: return @"MH_MAGIC";
      case MH_CIGAM: return @"MH_CIGAM";
      case MH_MAGIC_64: return @"MH_MAGIC_64";
      case MH_CIGAM_64: return @"MH_CIGAM_64";
    }

    return [NSString stringWithFormat:@"0x%08x", magic];
}

@implementation CDMachOFile

// Returns either a CDMachOFile or CDFatFile.
+ (id)machOFileWithFilename:(NSString *)aFilename;
{
    NSData *data;
    CDFatFile *aFatFile;
    CDMachOFile *aMachOFile;

    data = [[NSData alloc] initWithContentsOfMappedFile:aFilename];

    aFatFile = [[[CDFatFile alloc] initWithData:data] autorelease];
    if (aFatFile == nil) {
        aMachOFile = [[[CDMachOFile alloc] initWithData:data] autorelease];
        if (aMachOFile == nil) {
            fprintf(stderr, "class-dump: Input file (%s) is neither a Mach-O file nor a fat archive.\n", [aFilename fileSystemRepresentation]);
            [data release];
            return nil;
        }

        NSLog(@"amof: %@", aMachOFile);
        return aMachOFile;
    }

    [data release];

    return aFatFile;
}

- (id)initWithData:(NSData *)_data;
{
    CDDataCursor *cursor;

    if ([super init] == nil)
        return nil;

    cursor = [[CDDataCursor alloc] initWithData:_data];
    magic = [cursor readLittleInt32];

    NSLog(@"magic: 0x%x", magic);
    if (magic == MH_MAGIC) {
        byteOrder = CDByteOrderLittleEndian;
    } else if (magic == MH_MAGIC_64) {
        NSLog(@"64 bit header...");
        byteOrder = CDByteOrderLittleEndian;
    } if (magic == MH_CIGAM) {
        byteOrder = CDByteOrderBigEndian;
    } else if (magic == MH_CIGAM_64) {
        NSLog(@"64 bit header...");
        byteOrder = CDByteOrderBigEndian;
    } else {
        NSLog(@"Not a mach-o file.");
        [cursor release];
        [self release];
        return nil;
    }

    NSLog(@"byte order: %d", byteOrder);
    [cursor setByteOrder:byteOrder];

    cputype = [cursor readInt32];
    NSLog(@"cputype: 0x%08x", cputype);

    _flags.uses64BitABI = (cputype & CPU_ARCH_MASK) == CPU_ARCH_ABI64;
    cputype &= ~CPU_ARCH_MASK;

    nonretainedDelegate = nil;

    return self;
}

#if 0
- (id)initWithFilename:(NSString *)aFilename archiveOffset:(unsigned int)anArchiveOffset;
{
    const struct mach_header *headerPtr;

    if ([super init] == nil)
        return nil;

    data = [[NSData alloc] initWithContentsOfMappedFile:aFilename];
    if (data == nil) {
        NSLog(@"Couldn't read file: %@", aFilename);
        [self release];
        return nil;
        //[NSException raise:NSGenericException format:@"Couldn't read file: %@", filename];
    }

    archiveOffset = anArchiveOffset;
    headerPtr = [data bytes] + archiveOffset;
    header = *headerPtr;

    if (header.magic == MH_MAGIC_64 || header.magic == MH_CIGAM_64) {
        NSLog(@"We don't support 64-bit Mach-O files.");
        [self release];
        return nil;
    }

    if (header.magic != MH_MAGIC && header.magic != MH_CIGAM) {
        [self release];
        return nil;
    }

    filename = [aFilename retain];
    loadCommands = [[NSMutableArray alloc] init];
    nonretainedDelegate = nil;

    return self;
}
#endif

- (void)dealloc;
{
    //[filename release];
    [loadCommands release]; // These all reference data, so release them first...  Should they just retain data themselves?
    [data release];
    nonretainedDelegate = nil;

    [super dealloc];
}

- (NSString *)bestMatchForLocalArch;
{
    return CDNameForCPUType(cputype, cpusubtype);
}

- (CDMachOFile *)machOFileWithArchName:(NSString *)name;
{
    const NXArchInfo *archInfo;

    archInfo = NXGetArchInfoFromName([name UTF8String]);
    if (archInfo == NULL)
        return nil;

    if (archInfo->cputype == cputype)
        return self;

    return nil;
}

- (NSString *)filename;
{
    return nil;
}

- (id)delegate;
{
    return nonretainedDelegate;
}

- (void)setDelegate:(id)newDelegate;
{
    nonretainedDelegate = newDelegate;
}

- (void)process;
{
    loadCommands = [[self _processLoadCommands] retain];
}

- (NSArray *)_processLoadCommands;
{
#if 0
    NSMutableArray *cmds;
    int count, index;
    const void *ptr;

    cmds = [NSMutableArray array];

    ptr = [self bytes] + sizeof(struct mach_header);
    count = header.ncmds;
    for (index = 0; index < count; index++) {
        CDLoadCommand *loadCommand;

        loadCommand = [CDLoadCommand loadCommandWithPointer:ptr machOFile:self];
        [cmds addObject:loadCommand];
        if ([loadCommand isKindOfClass:[CDDylibCommand class]] == YES) {
            [nonretainedDelegate machOFile:self loadDylib:(CDDylibCommand *)loadCommand];
        }

        //NSLog(@"cmdsize: 0x%x\n", [loadCommand cmdsize]);
        ptr += [loadCommand cmdsize];
    }

    return [NSArray arrayWithArray:cmds];;
#endif
    return nil;
}

- (cpu_type_t)cpuType;
{
    return cputype;
}

- (cpu_subtype_t)cpuSubtype;
{
    return cpusubtype;
}

- (uint32_t)filetype;
{
    return filetype;
}

- (uint32_t)flags;
{
    return flags;
}

- (NSArray *)loadCommands;
{
    return loadCommands;
}

- (NSString *)filetypeDescription;
{
    switch ([self filetype]) {
      case MH_OBJECT: return @"OBJECT";
      case MH_EXECUTE: return @"EXECUTE";
      case MH_FVMLIB: return @"FVMLIB";
      case MH_CORE: return @"CORE";
      case MH_PRELOAD: return @"PRELOAD";
      case MH_DYLIB: return @"DYLIB";
      case MH_DYLINKER: return @"DYLINKER";
      case MH_BUNDLE: return @"BUNDLE";
      case MH_DYLIB_STUB: return @"DYLIB_STUB";
      case MH_DSYM: return @"DSYM";
      default:
          break;
    }

    return nil;
}

- (NSString *)flagDescription;
{
    NSMutableArray *setFlags;

    setFlags = [NSMutableArray array];
    flags = [self flags];
    if (flags & MH_NOUNDEFS)
        [setFlags addObject:@"NOUNDEFS"];
    if (flags & MH_INCRLINK)
        [setFlags addObject:@"INCRLINK"];
    if (flags & MH_DYLDLINK)
        [setFlags addObject:@"DYLDLINK"];
    if (flags & MH_BINDATLOAD)
        [setFlags addObject:@"BINDATLOAD"];
    if (flags & MH_PREBOUND)
        [setFlags addObject:@"PREBOUND"];
    if (flags & MH_SPLIT_SEGS)
        [setFlags addObject:@"SPLIT_SEGS"];
    if (flags & MH_LAZY_INIT)
        [setFlags addObject:@"LAZY_INIT"];
    if (flags & MH_TWOLEVEL)
        [setFlags addObject:@"TWOLEVEL"];
    if (flags & MH_FORCE_FLAT)
        [setFlags addObject:@"FORCE_FLAT"];
    if (flags & MH_NOMULTIDEFS)
        [setFlags addObject:@"NOMULTIDEFS"];
    if (flags & MH_NOFIXPREBINDING)
        [setFlags addObject:@"NOFIXPREBINDING"];
    if (flags & MH_PREBINDABLE)
        [setFlags addObject:@"PREBINDABLE"];
    if (flags & MH_ALLMODSBOUND)
        [setFlags addObject:@"ALLMODSBOUND"];
    if (flags & MH_SUBSECTIONS_VIA_SYMBOLS)
        [setFlags addObject:@"SUBSECTIONS_VIA_SYMBOLS"];
    if (flags & MH_CANONICAL)
        [setFlags addObject:@"CANONICAL"];
    if (flags & MH_WEAK_DEFINES)
        [setFlags addObject:@"WEAK_DEFINES"];
    if (flags & MH_BINDS_TO_WEAK)
        [setFlags addObject:@"BINDS_TO_WEAK"];
    if (flags & MH_ALLOW_STACK_EXECUTION)
        [setFlags addObject:@"ALLOW_STACK_EXECUTION"];
#if 1
    // 10.5 only, but I'm still using the 10.4 sdk.
    if (flags & MH_ROOT_SAFE)
        [setFlags addObject:@"ROOT_SAFE"];
    if (flags & MH_SETUID_SAFE)
        [setFlags addObject:@"SETUID_SAFE"];
    if (flags & MH_NO_REEXPORTED_DYLIBS)
        [setFlags addObject:@"NO_REEXPORTED_DYLIBS"];
    if (flags & MH_PIE)
        [setFlags addObject:@"PIE"];
#endif

    return [setFlags componentsJoinedByString:@" "];
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"magic: 0x%08x, cputype: %d, cpusubtype: %d, filetype: %d, ncmds: %d, sizeofcmds: %d, flags: 0x%x, uses64BitABI? %d",
                     magic, cputype, cpusubtype, filetype, [loadCommands count], 0, flags, _flags.uses64BitABI];
}

- (CDDylibCommand *)dylibIdentifier;
{
    int count, index;

    count = [loadCommands count];
    for (index = 0; index < count; index++) {
        CDLoadCommand *loadCommand;

        loadCommand = [loadCommands objectAtIndex:index];
        if ([loadCommand cmd] == LC_ID_DYLIB)
            return (CDDylibCommand *)loadCommand;
    }

    return nil;
}

- (CDSegmentCommand *)segmentWithName:(NSString *)segmentName;
{
    int count, index;

    count = [loadCommands count];
    for (index = 0; index < count; index++) {
        id loadCommand;

        loadCommand = [loadCommands objectAtIndex:index];
        if ([loadCommand isKindOfClass:[CDSegmentCommand class]] == YES && [[loadCommand name] isEqual:segmentName] == YES) {
            return loadCommand;
        }
    }

    return nil;
}

- (CDSegmentCommand *)segmentContainingAddress:(unsigned long)vmaddr;
{
    int count, index;

    count = [loadCommands count];
    for (index = 0; index < count; index++) {
        id loadCommand;

        loadCommand = [loadCommands objectAtIndex:index];
        if ([loadCommand isKindOfClass:[CDSegmentCommand class]] == YES && [loadCommand containsAddress:vmaddr] == YES) {
            return loadCommand;
        }
    }

    return nil;
}

- (void)foo;
{
    NSLog(@"busted");
}

- (void)showWarning:(NSString *)aWarning;
{
    NSLog(@"Warning: %@", aWarning);
}

- (const void *)pointerFromVMAddr:(unsigned long)vmaddr;
{
    return [self pointerFromVMAddr:vmaddr segmentName:nil]; // Any segment is fine
}

- (const void *)pointerFromVMAddr:(unsigned long)vmaddr segmentName:(NSString *)aSegmentName;
{
#if 0
    CDSegmentCommand *segment;
    const void *ptr;

    if (vmaddr == 0)
        return NULL;

    segment = [self segmentContainingAddress:vmaddr];
    if (segment == NULL) {
        [self foo];
        //NSLog(@"load commands: %@", [loadCommands description]);
        NSLog(@"pointerFromVMAddr:, vmaddr: %p, segment: %@", vmaddr, segment);
    }
    //NSLog(@"[segment name]: %@", [segment name]);
    if (aSegmentName != nil && [[segment name] isEqual:aSegmentName] == NO) {
        //[self showWarning:[NSString stringWithFormat:@"addr %p in segment %@, required segment is %@", vmaddr, [segment name], aSegmentName]];
        return NULL;
    }
    if ([segment isProtected]) {
        //NSLog(@"Arg, a protected segment.");
        return NULL;
    }
#if 0
    NSLog(@"vmaddr: %p, [data bytes]: %p, [segment fileoff]: %d, [segment segmentOffsetForVMAddr:vmaddr]: %d",
          vmaddr, [data bytes], [segment fileoff], [segment segmentOffsetForVMAddr:vmaddr]);
#endif
    ptr = [data bytes] + archiveOffset + (vmaddr - [segment vmaddr] + [segment fileoff]);
    //ptr = [data bytes] + [segment fileoff] + [segment segmentOffsetForVMAddr:vmaddr];
    return ptr;
#endif
    return NULL;
}

- (NSString *)stringFromVMAddr:(unsigned long)vmaddr;
{
    const void *ptr;

    ptr = [self pointerFromVMAddr:vmaddr];
    if (ptr == NULL)
        return nil;

    return [[[NSString alloc] initWithBytes:ptr length:strlen(ptr) encoding:NSASCIIStringEncoding] autorelease];
}

- (const void *)bytes;
{
    return [data bytes];
}

- (const void *)bytesAtOffset:(unsigned long)offset;
{
    return [data bytes] + offset;
}

- (NSString *)importBaseName;
{
#if 0
    if ([self filetype] == MH_DYLIB) {
        NSString *str;

        str = [filename lastPathComponent];
        if ([str hasPrefix:@"lib"] == YES)
            str = [[[str substringFromIndex:3] componentsSeparatedByString:@"."] objectAtIndex:0];

        return str;
    }
#endif
    return nil;
}

- (BOOL)hasProtectedSegments;
{
    unsigned int count, index;

    count = [loadCommands count];
    for (index = 0; index < count; index++) {
        CDLoadCommand *loadCommand;

        loadCommand = [loadCommands objectAtIndex:index];
        if ([loadCommand isKindOfClass:[CDSegmentCommand class]] && [(CDSegmentCommand *)loadCommand isProtected])
            return YES;
    }

    return NO;
}

- (NSString *)loadCommandString:(BOOL)isVerbose;
{
    NSMutableString *resultString;
    unsigned int count, index;

    resultString = [NSMutableString string];
    count = [loadCommands count];
    for (index = 0; index < count; index++) {
        CDLoadCommand *loadCommand;

        [resultString appendFormat:@"Load command %u\n", index];
        loadCommand = [loadCommands objectAtIndex:index];
        [loadCommand appendToString:resultString verbose:isVerbose];
        [resultString appendString:@"\n"];
    }

    return resultString;
}

- (NSString *)headerString:(BOOL)isVerbose;
{
    NSMutableString *resultString;

    resultString = [NSMutableString string];
    [resultString appendString:@"Mach header\n"];
    [resultString appendString:@"      magic cputype cpusubtype   filetype ncmds sizeofcmds      flags\n"];
    // Grr, %11@ doesn't work.
    if (isVerbose)
        [resultString appendFormat:@"%11@ %7@ %10u   %8@ %5u %10u %@\n",
                      CDMagicNumberString(magic), CDNameForCPUType(cputype, cpusubtype), cpusubtype,
                      [self filetypeDescription], [loadCommands count], 0, [self flagDescription]];
    else
        [resultString appendFormat:@" 0x%08x %7u %10u   %8u %5u %10u 0x%08x\n",
                      magic, cputype, cpusubtype, filetype, [loadCommands count], 0, flags];
    [resultString appendString:@"\n"];

    return resultString;
}

// Must not return nil.
- (NSString *)archName;
{
    return CDNameForCPUType(cputype, cpusubtype);
}

//
// To remove:
//

- (BOOL)hasDifferentByteOrder;
{
    return NO;
}

@end
