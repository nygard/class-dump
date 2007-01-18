//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2006  Steve Nygard

#import "CDLoadCommand.h"

#include <mach-o/swap.h>
#import <Foundation/Foundation.h>
#import "CDFatFile.h" // For CD_THIS_BYTE_ORDER
#import "CDSegmentCommand.h"
#import "CDDylibCommand.h"
#import "CDMachOFile.h"
#import "CDSymbolTable.h"
#import "CDDynamicSymbolTable.h"
#import "CDUUIDCommand.h"

@implementation CDLoadCommand

+ (id)loadCommandWithPointer:(const void *)ptr machOFile:(CDMachOFile *)aMachOFile;
{
    struct load_command lc;
    Class targetClass = [CDLoadCommand class];

    lc = *(struct load_command *)ptr;
    if ([aMachOFile hasDifferentByteOrder] == YES)
        swap_load_command(&lc, CD_THIS_BYTE_ORDER);

    if (lc.cmd == LC_SEGMENT)
        targetClass = [CDSegmentCommand class];
    if (lc.cmd == LC_ID_DYLIB || lc.cmd == LC_LOAD_DYLIB || lc.cmd == LC_LOAD_WEAK_DYLIB)
        targetClass = [CDDylibCommand class];
    if (lc.cmd == LC_SYMTAB)
        targetClass = [CDSymbolTable class];
    if (lc.cmd == LC_DYSYMTAB)
        targetClass = [CDDynamicSymbolTable class];
    if (lc.cmd == LC_UUID)
        targetClass = [CDUUIDCommand class];

    return [[[targetClass alloc] initWithPointer:ptr machOFile:aMachOFile] autorelease];
}

- (id)initWithPointer:(const void *)ptr machOFile:(CDMachOFile *)aMachOFile;
{
    if ([super init] == nil)
        return nil;

    nonretainedMachOFile = aMachOFile;
    loadCommand = *(struct load_command *)ptr;
    if ([aMachOFile hasDifferentByteOrder] == YES)
        swap_load_command(&loadCommand, CD_THIS_BYTE_ORDER);

    return self;
}

- (CDMachOFile *)machOFile;
{
    return nonretainedMachOFile;
}

- (unsigned long)cmd;
{
    return loadCommand.cmd;
}

- (unsigned long)cmdsize;
{
    return loadCommand.cmdsize;
}

- (NSString *)commandName;
{
    switch (loadCommand.cmd) {
      case LC_SEGMENT: return @"SEGMENT";
      case LC_SYMTAB: return @"SYMTAB";
      case LC_SYMSEG: return @"SYMSEG";
      case LC_THREAD: return @"THREAD";
      case LC_UNIXTHREAD: return @"UNIXTHREAD";
      case LC_LOADFVMLIB: return @"LOADFVMLIB";
      case LC_IDFVMLIB: return @"IDFVMLIB";
      case LC_IDENT: return @"IDENT";
      case LC_FVMFILE: return @"FVMFILE";
      case LC_PREPAGE: return @"PREPAGE";
      case LC_DYSYMTAB: return @"DYSYMTAB";
      case LC_LOAD_DYLIB: return @"LOAD_DYLIB";
      case LC_ID_DYLIB: return @"ID_DYLIB";
      case LC_LOAD_DYLINKER: return @"LOAD_DYLINKER";
      case LC_ID_DYLINKER: return @"ID_DYLINKER";
      case LC_PREBOUND_DYLIB: return @"PREBOUND_DYLIB";
      case LC_ROUTINES: return @"ROUTINES";
      case LC_SUB_FRAMEWORK: return @"SUB_FRAMEWORK";
      case LC_SUB_UMBRELLA: return @"SUB_UMBRELLA";
      case LC_SUB_CLIENT: return @"SUB_CLIENT";
      case LC_SUB_LIBRARY: return @"SUB_LIBRARY";
      case LC_TWOLEVEL_HINTS: return @"TWOLEVEL_HINTS";
      case LC_PREBIND_CKSUM: return @"PREBIND_CKSUM";
      case LC_LOAD_WEAK_DYLIB: return @"LOAD_WEAK_DYLIB";
      case LC_SEGMENT_64: return @"SEGMENT_64";
      case LC_ROUTINES_64: return @"ROUTINES_64";
      case LC_UUID: return @"UUID";
      default:
          break;
    }

    return @"<unknown load command>";
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] cmd: %d (%@), cmdsize: %d // %@", NSStringFromClass([self class]), loadCommand.cmd, [self commandName], loadCommand.cmdsize, [self extraDescription]];
}

- (NSString *)extraDescription;
{
    return @"";
}

- (void)appendToString:(NSMutableString *)resultString;
{
    [resultString appendFormat:@"     cmd LC_%@\n", [self commandName]];
    [resultString appendFormat:@" cmdsize %u\n", loadCommand.cmdsize];
}

@end
