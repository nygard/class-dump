// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDLCEncryptionInfo.h"

// This is used on iOS.

@implementation CDLCEncryptionInfo
{
    struct encryption_info_command_64 _encryptionInfoCommand;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        _encryptionInfoCommand.cmd     = [cursor readInt32];
        _encryptionInfoCommand.cmdsize = [cursor readInt32];
        
        _encryptionInfoCommand.cryptoff  = [cursor readInt32];
        _encryptionInfoCommand.cryptsize = [cursor readInt32];
        _encryptionInfoCommand.cryptid   = [cursor readInt32];
        if (_encryptionInfoCommand.cmd == LC_ENCRYPTION_INFO_64) {
            _encryptionInfoCommand.pad = [cursor readInt32];
        }
    }

    return self;
}

#pragma mark -

- (uint32_t)cmd;
{
    return _encryptionInfoCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return _encryptionInfoCommand.cmdsize;
}

- (uint32_t)cryptoff;
{
    return _encryptionInfoCommand.cryptoff;
}

- (uint32_t)cryptsize;
{
    return _encryptionInfoCommand.cryptsize;
}

- (uint32_t)cryptid;
{
    return _encryptionInfoCommand.cryptid;
}

- (BOOL)isEncrypted;
{
    return _encryptionInfoCommand.cryptid != 0;
}

@end
