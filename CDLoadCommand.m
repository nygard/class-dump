//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import "CDLoadCommand.h"

#import <Foundation/Foundation.h>
#import "CDSegmentCommand.h"
#import "CDDylibCommand.h"

@implementation CDLoadCommand

+ (id)loadCommandWithPointer:(const void *)ptr machOFile:(CDMachOFile *)aMachOFile;
{
    const struct load_command *lc = ptr;
    Class targetClass = [CDLoadCommand class];

    if (lc->cmd == LC_SEGMENT)
        targetClass = [CDSegmentCommand class];
    if (lc->cmd == LC_ID_DYLIB || lc->cmd == LC_LOAD_DYLIB || lc->cmd == LC_LOAD_WEAK_DYLIB)
        targetClass = [CDDylibCommand class];

    return [[[targetClass alloc] initWithPointer:ptr machOFile:aMachOFile] autorelease];
}

- (id)initWithPointer:(const void *)ptr machOFile:(CDMachOFile *)aMachOFile;
{
    if ([super init] == nil)
        return nil;

    nonretainedMachOFile = aMachOFile;
    loadCommand = ptr;

    return self;
}

- (CDMachOFile *)machOFile;
{
    return nonretainedMachOFile;
}

- (const void *)bytes;
{
    return loadCommand;
}

- (unsigned long)cmd;
{
    return loadCommand->cmd;
}

- (unsigned long)cmdsize;
{
    return loadCommand->cmdsize;
}

- (NSString *)commandName;
{
    unsigned long cmd = loadCommand->cmd;

    switch (cmd) {
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
      default:
          break;
    }

    return @"<unknown load command>";
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] cmd: %d (%@), cmdsize: %d // %@", NSStringFromClass([self class]), loadCommand->cmd, [self commandName], loadCommand->cmdsize, [self extraDescription]];
}

- (NSString *)extraDescription;
{
    return @"";
}

@end
