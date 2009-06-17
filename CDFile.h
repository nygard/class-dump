// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2009 Steve Nygard.  All rights reserved.

#import <Foundation/Foundation.h>

#include <mach-o/arch.h>
#include <mach-o/loader.h>
#include <mach-o/fat.h>
#include <mach-o/swap.h>

@class CDMachOFile;

extern NSString *CDNameForCPUType(cpu_type_t cputype, cpu_subtype_t cpusubtype);

@interface CDFile : NSObject
{
}

+ (id)fileWithData:(NSData *)data;

- (id)initWithData:(NSData *)data;

- (NSString *)bestMatchForLocalArch;
- (CDMachOFile *)machOFileWithArchName:(NSString *)name;

@end
