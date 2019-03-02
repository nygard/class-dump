// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "CDLoadCommand.h"

@interface CDLCEncryptionInfo : CDLoadCommand

@property (nonatomic, readonly) uint32_t cryptoff;
@property (nonatomic, readonly) uint32_t cryptsize;
@property (nonatomic, readonly) uint32_t cryptid;

@property (nonatomic, readonly) BOOL isEncrypted;

@end
