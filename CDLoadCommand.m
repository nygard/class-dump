//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import "CDLoadCommand.h"

#import "rcsid.h"
#import <Foundation/Foundation.h>
#import "CDSegmentCommand.h"
#import "CDDylibCommand.h"

RCS_ID("$Header: /Volumes/Data/tmp/Tools/class-dump/CDLoadCommand.m,v 1.5 2004/01/06 02:31:40 nygard Exp $");

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

    if (cmd == LC_SEGMENT) return @"SEGMENT";
    if (cmd == LC_SYMTAB) return @"SYMTAB";
    if (cmd == LC_SYMSEG) return @"SYMSEG";
    if (cmd == LC_THREAD) return @"THREAD";
    if (cmd == LC_UNIXTHREAD) return @"UNIXTHREAD";
    if (cmd == LC_LOADFVMLIB) return @"LOADFVMLIB";
    if (cmd == LC_IDFVMLIB) return @"IDFVMLIB";
    if (cmd == LC_IDENT) return @"IDENT";
    if (cmd == LC_FVMFILE) return @"FVMFILE";
    if (cmd == LC_PREPAGE) return @"PREPAGE";
    if (cmd == LC_DYSYMTAB) return @"DYSYMTAB";
    if (cmd == LC_LOAD_DYLIB) return @"LOAD_DYLIB";
    if (cmd == LC_ID_DYLIB) return @"ID_DYLIB";
    if (cmd == LC_LOAD_DYLINKER) return @"LOAD_DYLINKER";
    if (cmd == LC_ID_DYLINKER) return @"ID_DYLINKER";
    if (cmd == LC_PREBOUND_DYLIB) return @"PREBOUND_DYLIB";
    if (cmd == LC_ROUTINES) return @"ROUTINES";
    if (cmd == LC_SUB_FRAMEWORK) return @"SUB_FRAMEWORK";
    if (cmd == LC_SUB_UMBRELLA) return @"SUB_UMBRELLA";
    if (cmd == LC_SUB_CLIENT) return @"SUB_CLIENT";
    if (cmd == LC_SUB_LIBRARY) return @"SUB_LIBRARY";
    if (cmd == LC_TWOLEVEL_HINTS) return @"TWOLEVEL_HINTS";
    if (cmd == LC_PREBIND_CKSUM) return @"PREBIND_CKSUM";
    if (cmd == LC_LOAD_WEAK_DYLIB) return @"LOAD_WEAK_DYLIB";

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
