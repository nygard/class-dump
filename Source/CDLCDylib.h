// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "CDLoadCommand.h"

@interface CDLCDylib : CDLoadCommand

@property (readonly) NSString *path;
@property (nonatomic, readonly) uint32_t timestamp;
@property (nonatomic, readonly) uint32_t currentVersion;
@property (nonatomic, readonly) uint32_t compatibilityVersion;

@property (nonatomic, readonly) NSString *formattedCurrentVersion;
@property (nonatomic, readonly) NSString *formattedCompatibilityVersion;

@end
