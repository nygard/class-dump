// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDLoadCommand.h"

#ifndef LC_ENCRYPTION_INFO_64
#define LC_ENCRYPTION_INFO_64 0x2C
#endif

@interface CDLCEncryptionInfo : CDLoadCommand

@property (nonatomic, readonly) uint32_t cryptoff;
@property (nonatomic, readonly) uint32_t cryptsize;
@property (nonatomic, readonly) uint32_t cryptid;

@property (nonatomic, readonly) BOOL isEncrypted;

@end
