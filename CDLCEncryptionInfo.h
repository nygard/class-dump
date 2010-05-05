// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDLoadCommand.h"

@interface CDLCEncryptionInfo : CDLoadCommand
{
    struct encryption_info_command encryptionInfoCommand;
}

- (id)initWithDataCursor:(CDDataCursor *)cursor machOFile:(CDMachOFile *)aMachOFile;

- (uint32_t)cmd;
- (uint32_t)cmdsize;

- (uint32_t)cryptoff;
- (uint32_t)cryptsize;
- (uint32_t)cryptid;

- (BOOL)isEncrypted;

@end
