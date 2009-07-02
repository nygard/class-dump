// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import "CDLoadCommand.h"

#include <mach-o/swap.h>

#import "CDLCDylib.h"
#import "CDLCDylinker.h"
#import "CDLCDynamicSymbolTable.h"
#import "CDLCLinkeditData.h"
#import "CDLCPreboundDylib.h"
#import "CDLCRoutines32.h"
#import "CDLCRoutines64.h"
#import "CDLCRunPath.h"
#import "CDLCSegment32.h"
#import "CDLCSegment64.h"
#import "CDLCSymbolTable.h"
#import "CDLCUUID.h"
#import "CDLCUnknown.h"
#import "CDMachOFile.h"
#import "CDLCUnixThread.h"

@implementation CDLoadCommand

//+ (id)loadCommandWithPointer:(const void *)ptr machOFile:(CDMachOFile *)aMachOFile;
+ (id)loadCommandWithDataCursor:(CDDataCursor *)cursor machOFile:(CDMachOFile *)aMachOFile;
{
    Class targetClass = [CDLCUnknown class];
    unsigned int val;

    val = [cursor peekInt32];

    switch (val) {
      case LC_SEGMENT: targetClass = [CDLCSegment32 class]; break;
      case LC_SEGMENT_64: targetClass = [CDLCSegment64 class]; break;
      case LC_ID_DYLIB:
      case LC_LOAD_DYLIB:
      case LC_LOAD_WEAK_DYLIB:
      case LC_REEXPORT_DYLIB:
          targetClass = [CDLCDylib class];
          break;
      case LC_SYMTAB:
          targetClass = [CDLCSymbolTable class];
          break;
      case LC_DYSYMTAB: targetClass = [CDLCDynamicSymbolTable class]; break;
      case LC_UUID: targetClass = [CDLCUUID class]; break;
      case LC_CODE_SIGNATURE:
      case LC_SEGMENT_SPLIT_INFO:
          targetClass = [CDLCLinkeditData class];
          break;
      case LC_UNIXTHREAD: targetClass = [CDLCUnixThread class]; break;
      case LC_LOAD_DYLINKER:
      case LC_ID_DYLINKER:
          targetClass = [CDLCDylinker class];
          break;
      case LC_ROUTINES: targetClass = [CDLCRoutines32 class]; break;
      case LC_ROUTINES_64: targetClass = [CDLCRoutines64 class]; break;
      case LC_RPATH: targetClass = [CDLCRunPath class]; break;
      case LC_PREBOUND_DYLIB: targetClass = [CDLCPreboundDylib class]; break;
      default:
          NSLog(@"Unknown load command: 0x%08x", val);
    };

    //NSLog(@"targetClass: %@", NSStringFromClass(targetClass));

    return [[[targetClass alloc] initWithDataCursor:cursor machOFile:aMachOFile] autorelease];
}

- (id)initWithDataCursor:(CDDataCursor *)cursor machOFile:(CDMachOFile *)aMachOFile;
{
    if ([super init] == nil)
        return nil;

    nonretainedMachOFile = aMachOFile;

    return self;
}

- (CDMachOFile *)machOFile;
{
    return nonretainedMachOFile;
}

- (uint32_t)cmd;
{
    // Implement in subclasses
    [NSException raise:NSGenericException format:@"Must implement method in subclasses."];
    return 0;
}

- (uint32_t)cmdsize;
{
    // Implement in subclasses
    [NSException raise:NSGenericException format:@"Must implement method in subclasses."];
    return 0;
}

- (NSString *)commandName;
{
    switch ([self cmd]) {
      case LC_SEGMENT: return @"LC_SEGMENT";
      case LC_SYMTAB: return @"LC_SYMTAB";
      case LC_SYMSEG: return @"LC_SYMSEG";
      case LC_THREAD: return @"LC_THREAD";
      case LC_UNIXTHREAD: return @"LC_UNIXTHREAD";
      case LC_LOADFVMLIB: return @"LC_LOADFVMLIB";
      case LC_IDFVMLIB: return @"LC_IDFVMLIB";
      case LC_IDENT: return @"LC_IDENT";
      case LC_FVMFILE: return @"LC_FVMFILE";
      case LC_PREPAGE: return @"LC_PREPAGE";
      case LC_DYSYMTAB: return @"LC_DYSYMTAB";
      case LC_LOAD_DYLIB: return @"LC_LOAD_DYLIB";
      case LC_ID_DYLIB: return @"LC_ID_DYLIB";
      case LC_LOAD_DYLINKER: return @"LC_LOAD_DYLINKER";
      case LC_ID_DYLINKER: return @"LC_ID_DYLINKER";
      case LC_PREBOUND_DYLIB: return @"LC_PREBOUND_DYLIB";
      case LC_ROUTINES: return @"LC_ROUTINES";
      case LC_SUB_FRAMEWORK: return @"LC_SUB_FRAMEWORK";
      case LC_SUB_UMBRELLA: return @"LC_SUB_UMBRELLA";
      case LC_SUB_CLIENT: return @"LC_SUB_CLIENT";
      case LC_SUB_LIBRARY: return @"LC_SUB_LIBRARY";
      case LC_TWOLEVEL_HINTS: return @"LC_TWOLEVEL_HINTS";
      case LC_PREBIND_CKSUM: return @"LC_PREBIND_CKSUM";
      case LC_LOAD_WEAK_DYLIB: return @"LC_LOAD_WEAK_DYLIB";
      case LC_SEGMENT_64: return @"LC_SEGMENT_64";
      case LC_ROUTINES_64: return @"LC_ROUTINES_64";
      case LC_UUID: return @"LC_UUID";
      case LC_RPATH: return @"LC_RPATH";
      case LC_CODE_SIGNATURE: return @"LC_CODE_SIGNATURE";
      case LC_REEXPORT_DYLIB: return @"LC_REEXPORT_DYLIB";
      case LC_LAZY_LOAD_DYLIB: return @"LC_LAZY_LOAD_DYLIB";
      case LC_ENCRYPTION_INFO: return @"LC_ENCRYPTION_INFO";
      default:
          break;
    }

    return [NSString stringWithFormat:@"0x%08x", [self cmd]];
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> cmd: 0x%08x (%@), cmdsize: %d // %@",
                     NSStringFromClass([self class]), self,
                     [self cmd], [self commandName], [self cmdsize], [self extraDescription]];
}

- (NSString *)extraDescription;
{
    return @"";
}

- (void)appendToString:(NSMutableString *)resultString verbose:(BOOL)isVerbose;
{
    [resultString appendFormat:@"     cmd %@", [self commandName]];
    if ([self mustUnderstandToExecute])
        [resultString appendFormat:@" (must understand to execute)"];
    [resultString appendFormat:@"\n"];
    [resultString appendFormat:@" cmdsize %u\n", [self cmdsize]];
}

- (BOOL)mustUnderstandToExecute;
{
    return ([self cmd] & LC_REQ_DYLD) != 0;
}

@end
