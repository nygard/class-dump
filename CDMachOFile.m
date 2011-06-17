// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2011 Steve Nygard.

#import "CDMachOFile.h"

#include <mach-o/arch.h>
#include <mach-o/loader.h>
#include <mach-o/fat.h>

#import "CDMachOFileDataCursor.h"
#import "CDFatFile.h"
#import "CDLoadCommand.h"
#import "CDLCDyldInfo.h"
#import "CDLCDylib.h"
#import "CDLCDynamicSymbolTable.h"
#import "CDLCEncryptionInfo.h"
#import "CDLCRunPath.h"
#import "CDLCSegment.h"
#import "CDLCSegment64.h"
#import "CDLCSymbolTable.h"
#import "CDLCUUID.h"
#import "CDLCVersionMinimum.h"
#import "CDObjectiveC1Processor.h"
#import "CDObjectiveC2Processor.h"
#import "CDSection.h"
#import "CDSymbol.h"
#import "CDRelocationInfo.h"
#import "CDSearchPathState.h"

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

- (id)initWithData:(NSData *)someData archOffset:(NSUInteger)anOffset archSize:(NSUInteger)aSize filename:(NSString *)aFilename searchPathState:(CDSearchPathState *)aSearchPathState;
{
    if ((self = [super initWithData:someData archOffset:anOffset archSize:aSize filename:aFilename searchPathState:aSearchPathState])) {
        byteOrder = CDByteOrder_LittleEndian;
        loadCommands = [[NSMutableArray alloc] init];
        segments = [[NSMutableArray alloc] init];
        symbolTable = nil;
        dynamicSymbolTable = nil;
        dyldInfo = nil;
        minVersionMacOSX = nil;
        minVersionIOS = nil;
        runPaths = [[NSMutableArray alloc] init];
        dyldEnvironment = [[NSMutableArray alloc] init];
        reExportedDylibs = [[NSMutableArray alloc] init]; 
        
        CDDataCursor *cursor = [[CDDataCursor alloc] initWithData:someData offset:archOffset];
        header.magic = [cursor readBigInt32];
        if (header.magic == MH_MAGIC || header.magic == MH_MAGIC_64) {
            byteOrder = CDByteOrder_BigEndian;
        } else if (header.magic == MH_CIGAM || header.magic == MH_CIGAM_64) {
            byteOrder = CDByteOrder_LittleEndian;
        } else {
            [cursor release];
            [self release];
            return nil;
        }
        
        _flags.uses64BitABI = (header.magic == MH_MAGIC_64) || (header.magic == MH_CIGAM_64);
        
        header.cputype = [cursor readBigInt32];
        header.cpusubtype = [cursor readBigInt32];
        header.filetype = [cursor readBigInt32];
        header.ncmds = [cursor readBigInt32];
        header.sizeofcmds = [cursor readBigInt32];
        header.flags = [cursor readBigInt32];
        if (_flags.uses64BitABI) {
            header.reserved = [cursor readBigInt32];
        }
        
        [cursor release];
        
        if (byteOrder == CDByteOrder_LittleEndian) {
            header.cputype = OSSwapInt32(header.cputype);
            header.cpusubtype = OSSwapInt32(header.cpusubtype);
            header.filetype = OSSwapInt32(header.filetype);
            header.ncmds = OSSwapInt32(header.ncmds);
            header.sizeofcmds = OSSwapInt32(header.sizeofcmds);
            header.flags = OSSwapInt32(header.flags);
            header.reserved = OSSwapInt32(header.reserved);
        }
        
        NSAssert(_flags.uses64BitABI == CDArchUses64BitABI((CDArch){ .cputype = header.cputype, .cpusubtype = header.cpusubtype }), @"Header magic should match cpu arch");
        header.cputype &= ~CPU_ARCH_MASK;
        
        NSUInteger headerOffset = _flags.uses64BitABI ? sizeof(struct mach_header_64) : sizeof(struct mach_header);
        CDMachOFileDataCursor *fileCursor = [[CDMachOFileDataCursor alloc] initWithFile:self offset:headerOffset];
        [self _readLoadCommands:fileCursor count:header.ncmds];
        [fileCursor release];
    }

    return self;
}

- (void)_readLoadCommands:(CDMachOFileDataCursor *)cursor count:(uint32_t)count;
{
    uint32_t index;

    for (index = 0; index < count; index++) {
        CDLoadCommand *loadCommand;

        loadCommand = [CDLoadCommand loadCommandWithDataCursor:cursor];
        if (loadCommand != nil) {
            [loadCommands addObject:loadCommand];

            if (loadCommand.cmd == LC_VERSION_MIN_MACOSX)                        self.minVersionMacOSX = (CDLCVersionMinimum *)loadCommand;
            else if (loadCommand.cmd == LC_VERSION_MIN_IPHONEOS)                 self.minVersionIOS = (CDLCVersionMinimum *)loadCommand;
            else if (loadCommand.cmd == LC_DYLD_ENVIRONMENT)                     [self.dyldEnvironment addObject:loadCommand];
            else if (loadCommand.cmd == LC_REEXPORT_DYLIB)                       [self.reExportedDylibs addObject:loadCommand];
            else if ([loadCommand isKindOfClass:[CDLCSegment class]])            [segments addObject:loadCommand];
            else if ([loadCommand isKindOfClass:[CDLCSymbolTable class]])        [self setSymbolTable:(CDLCSymbolTable *)loadCommand];
            else if ([loadCommand isKindOfClass:[CDLCDynamicSymbolTable class]]) [self setDynamicSymbolTable:(CDLCDynamicSymbolTable *)loadCommand];
            else if ([loadCommand isKindOfClass:[CDLCDyldInfo class]])           [self setDyldInfo:(CDLCDyldInfo *)loadCommand];
            else if ([loadCommand isKindOfClass:[CDLCRunPath class]])            [runPaths addObject:[(CDLCRunPath *)loadCommand resolvedRunPath]];
        }
        //NSLog(@"loadCommand: %@", loadCommand);
    }
}

- (void)dealloc;
{
    [loadCommands release]; // These all reference data, so release them first...  Should they just retain data themselves?
    [segments release];
    [symbolTable release];
    [dynamicSymbolTable release];
    [dyldInfo release];
    [minVersionMacOSX release];
    [minVersionIOS release];
    [runPaths release];
    [dyldEnvironment release];
    [reExportedDylibs release];

    [super dealloc];
}

#pragma mark -

- (CDByteOrder)byteOrder;
{
    return byteOrder;
}

- (CDMachOFile *)machOFileWithArch:(CDArch)arch;
{
    if ([self cputype] == arch.cputype)
        return self;

    return nil;
}

- (uint32_t)magic;
{
    return header.magic;
}

- (cpu_type_t)cputype;
{
    return header.cputype;
}

- (cpu_subtype_t)cpusubtype;
{
    return header.cpusubtype;
}

// Well... only the arch bits it knows about.
- (cpu_type_t)cputypePlusArchBits;
{
    if ([self uses64BitABI])
        return [self cputype] | CPU_ARCH_ABI64;

    return [self cputype];
}

#if 0
- (const NXArchInfo *)archInfo;
{
    const NXArchInfo *archInfo;

    if ([self uses64BitABI]) {
        archInfo = NXGetArchInfoFromCpuType([self cputype] | CPU_ARCH_ABI64, [self cpusubtype]);
    } else {
        archInfo = NXGetArchInfoFromCpuType([self cputype], [self cpusubtype]);
    }

    return archInfo;
}
#endif

- (uint32_t)filetype;
{
    return header.filetype;
}

- (uint32_t)flags;
{
    return header.flags;
}

- (NSArray *)loadCommands;
{
    return loadCommands;
}

// TODO: Handle like run paths
- (NSArray *)dylibLoadCommands;
{
    NSMutableArray *dylibLoadCommands = [NSMutableArray array];
    for (id loadCommand in loadCommands) {
        if ([loadCommand isKindOfClass:[CDLCDylib class]])
            [dylibLoadCommands addObject:loadCommand];
    }
    return dylibLoadCommands;
}

- (NSArray *)segments;
{
    return segments;
}

@synthesize symbolTable;
@synthesize dynamicSymbolTable;
@synthesize dyldInfo;
@synthesize minVersionMacOSX;
@synthesize minVersionIOS;

- (BOOL)uses64BitABI;
{
    return _flags.uses64BitABI;
}

- (NSUInteger)ptrSize;
{
    return [self uses64BitABI] ? sizeof(uint64_t) : sizeof(uint32_t);
}
             
- (BOOL)bestMatchForLocalArch:(CDArch *)archPtr;
{
    if (archPtr != NULL) {
        archPtr->cputype = header.cputype;
        archPtr->cpusubtype = header.cpusubtype;
    }

    return YES;
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
    uint32_t flags;

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

- (CDLCDylib *)dylibIdentifier;
{
    for (CDLoadCommand *loadCommand in loadCommands) {
        if ([loadCommand cmd] == LC_ID_DYLIB)
            return (CDLCDylib *)loadCommand;
    }

    return nil;
}

#pragma mark -

- (CDLCSegment *)segmentWithName:(NSString *)segmentName;
{
    for (id loadCommand in loadCommands) {
        if ([loadCommand isKindOfClass:[CDLCSegment class]] && [[loadCommand name] isEqual:segmentName]) {
            return loadCommand;
        }
    }

    return nil;
}

- (CDLCSegment *)segmentContainingAddress:(NSUInteger)address;
{
    for (id loadCommand in loadCommands) {
        if ([loadCommand isKindOfClass:[CDLCSegment class]] && [loadCommand containsAddress:address]) {
            return loadCommand;
        }
    }

    return nil;
}

- (void)showWarning:(NSString *)aWarning;
{
    NSLog(@"Warning: %@", aWarning);
}

- (NSString *)stringAtAddress:(NSUInteger)address;
{
    CDLCSegment *segment;

    NSUInteger anOffset;
    const void *ptr;

    if (address == 0)
        return nil;

    segment = [self segmentContainingAddress:address];
    if (segment == nil) {
        NSLog(@"Error: Cannot find offset for address 0x%08lx in stringAtAddress:", address);
        exit(5);
        return nil;
    }

    if ([segment isProtected]) {
        NSData *d2;
        NSUInteger d2Offset;

        d2 = [segment decryptedData];
        d2Offset = [segment segmentOffsetForAddress:address];
        if (d2Offset == 0)
            return nil;

        ptr = [d2 bytes] + d2Offset;
        return [[[NSString alloc] initWithBytes:ptr length:strlen(ptr) encoding:NSASCIIStringEncoding] autorelease];
    }

    anOffset = archOffset + [self dataOffsetForAddress:address];
    if (anOffset == 0)
        return nil;

    ptr = [data bytes] + anOffset;

    return [[[NSString alloc] initWithBytes:ptr length:strlen(ptr) encoding:NSASCIIStringEncoding] autorelease];
}

- (NSData *)machOData;
{
    return [NSData dataWithBytesNoCopy:(void*)(archOffset + [data bytes]) length:archSize freeWhenDone:NO];
}

- (NSUInteger)dataOffsetForAddress:(NSUInteger)address;
{
    CDLCSegment *segment;

    if (address == 0)
        return 0;

    segment = [self segmentContainingAddress:address];
    if (segment == nil) {
        NSLog(@"Error: Cannot find offset for address 0x%08lx in dataOffsetForAddress:", address);
        exit(5);
    }

    if ([segment isProtected]) {
        NSLog(@"Error: Segment is protected.");
        exit(5);
    }

#if 0
    NSLog(@"---------->");
    NSLog(@"segment is: %@", segment);
    NSLog(@"address: 0x%08x", address);
    NSLog(@"CDFile offset:    0x%08x", offset);
    NSLog(@"file off for address: 0x%08x", [segment fileOffsetForAddress:address]);
    NSLog(@"data offset:      0x%08x", offset + [segment fileOffsetForAddress:address]);
    NSLog(@"<----------");
#endif
    return [segment fileOffsetForAddress:address];
}

- (const void *)bytes;
{
    return [data bytes];
}

- (const void *)bytesAtOffset:(NSUInteger)anOffset;
{
    return [data bytes] + anOffset;
}

- (NSString *)importBaseName;
{
    if ([self filetype] == MH_DYLIB) {
        NSString *str;

        str = [filename lastPathComponent];
        if ([str hasPrefix:@"lib"])
            str = [[[str substringFromIndex:3] componentsSeparatedByString:@"."] objectAtIndex:0];

        return str;
    }

    return nil;
}

#pragma mark -

- (BOOL)isEncrypted;
{
    for (CDLoadCommand *loadCommand in loadCommands) {
        if ([loadCommand isKindOfClass:[CDLCEncryptionInfo class]] && [(CDLCEncryptionInfo *)loadCommand isEncrypted]) {
            return YES;
        }
    }

    return NO;
}

- (BOOL)hasProtectedSegments;
{
    for (CDLoadCommand *loadCommand in loadCommands) {
        if ([loadCommand isKindOfClass:[CDLCSegment class]] && [(CDLCSegment *)loadCommand isProtected])
            return YES;
    }

    return NO;
}

- (BOOL)canDecryptAllSegments;
{
    for (CDLoadCommand *loadCommand in loadCommands) {
        if ([loadCommand isKindOfClass:[CDLCSegment class]] && [(CDLCSegment *)loadCommand canDecrypt] == NO)
            return NO;
    }

    return YES;
}

- (NSString *)loadCommandString:(BOOL)isVerbose;
{
    NSMutableString *resultString;
    NSUInteger count, index;

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
                      CDMagicNumberString([self magic]), [self archName], [self cpusubtype],
                      [self filetypeDescription], [loadCommands count], 0, [self flagDescription]];
    else
        [resultString appendFormat:@" 0x%08x %7u %10u   %8u %5u %10u 0x%08x\n",
                      [self magic], [self cputype], [self cpusubtype], [self filetype], [loadCommands count], 0, [self flags]];
    [resultString appendString:@"\n"];

    return resultString;
}

- (NSString *)uuidString;
{
    for (CDLoadCommand *loadCommand in loadCommands)
        if ([loadCommand isKindOfClass:[CDLCUUID class]])
            return [(CDLCUUID *)loadCommand uuidString];

    return @"N/A";
}

// Must not return nil.
- (NSString *)archName;
{
    return CDNameForCPUType([self cputype], [self cpusubtype]);
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> magic: 0x%08x, cputype: %x, cpusubtype: %x, filetype: %d, ncmds: %d, sizeofcmds: %d, flags: 0x%x, uses64BitABI? %d, filename: %@, data: %p, archOffset: %p",
                     NSStringFromClass([self class]), self,
                     [self magic], [self cputype], [self cpusubtype], [self filetype], [loadCommands count], 0, [self flags], _flags.uses64BitABI,
                     filename, data, archOffset];
}

- (void)logInfoForAddress:(NSUInteger)address;
{
    if (address != 0) {
        CDLCSegment *segment;
        NSString *str;

        segment = [self segmentContainingAddress:address];
        if (segment == nil) {
            NSLog(@"No segment contains address: %016lx", address);
        } else {
            CDSection *section;

            //NSLog(@"Found address %016lx in segment, sections= %@", address, [segment sections]);
            section = [segment sectionContainingAddress:address];
            if (section == nil) {
                NSLog(@"Found address %016lx in segment %@, but not in a section", address, [segment name]);
            } else {
                NSLog(@"Found address %016lx in segment %@, section %@", address, [segment name], [section sectionName]);
            }
        }

        str = [self stringAtAddress:address];
        NSLog(@"      address %016lx as a string: '%@' (length %lu)", address, str, [str length]);
        NSLog(@"      address %016lx data offset: %lu", address, [self dataOffsetForAddress:address]);
    }
}

- (NSString *)externalClassNameForAddress:(NSUInteger)address;
{
    CDRelocationInfo *rinfo;

    // Not for NSCFArray (NSMutableArray), NSSimpleAttributeDictionaryEnumerator (NSEnumerator), NSSimpleAttributeDictionary (NSDictionary), etc.
    // It turns out NSMutableArray is in /System/Library/Frameworks/CoreFoundation.framework/Versions/A/CoreFoundation, so...
    // ... it's an undefined symbol, need to look it up.
    rinfo = [dynamicSymbolTable relocationEntryWithOffset:address - [symbolTable baseAddress]];
    //NSLog(@"rinfo: %@", rinfo);
    if (rinfo != nil) {
        CDSymbol *symbol;
        NSString *str;

        symbol = [[symbolTable symbols] objectAtIndex:rinfo.symbolnum];
        //NSLog(@"symbol: %@", symbol);

        // Now we could use GET_LIBRARY_ORDINAL(), look up the the appropriate mach-o file (being sure to have loaded them even without -r),
        // look up the symbol in that mach-o file, get the address, look up the class based on that address, and finally get the class name
        // from that.

        // Or, we could be lazy and take advantage of the fact that the class name we're after is in the symbol name:
        str = [symbol name];
        if ([str hasPrefix:ObjCClassSymbolPrefix]) {
            return [str substringFromIndex:[ObjCClassSymbolPrefix length]];
        } else {
            NSLog(@"Warning: Unknown prefix on symbol name... %@ (addr %lx)", str, address);
            return str;
        }
    }

    // This is fine, they might really be root objects.  NSObject, NSProxy.
    return nil;
}

- (BOOL)hasRelocationEntryForAddress:(NSUInteger)address;
{
    CDRelocationInfo *rinfo;

    rinfo = [dynamicSymbolTable relocationEntryWithOffset:address - [symbolTable baseAddress]];
    //NSLog(@"%s, rinfo= %@", __cmd, rinfo);
    return rinfo != nil;
}

- (BOOL)hasRelocationEntryForAddress2:(NSUInteger)address;
{
    return [dyldInfo symbolNameForAddress:address] != nil;
}

- (NSString *)externalClassNameForAddress2:(NSUInteger)address;
{
    NSString *str = [dyldInfo symbolNameForAddress:address];

    if (str != nil) {
        if ([str hasPrefix:ObjCClassSymbolPrefix]) {
            return [str substringFromIndex:[ObjCClassSymbolPrefix length]];
        } else {
            NSLog(@"Warning: Unknown prefix on symbol name... %@ (addr %lx)", str, address);
            return str;
        }
    }

    return nil;
}

- (BOOL)hasObjectiveC1Data;
{
    return [self segmentWithName:@"__OBJC"] != nil;
}

- (BOOL)hasObjectiveC2Data;
{
    // http://twitter.com/gparker/status/17962955683
    return [[self segmentWithName:@"__DATA"] sectionWithName:@"__objc_imageinfo"] != nil;
}

- (Class)processorClass;
{
    if ([self hasObjectiveC2Data])
        return [CDObjectiveC2Processor class];
    
    return [CDObjectiveC1Processor class];
}

@synthesize runPaths;
@synthesize dyldEnvironment;
@synthesize reExportedDylibs;

@end
