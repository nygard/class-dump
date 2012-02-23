// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import <Foundation/Foundation.h>

#include <mach-o/arch.h>
#include <mach-o/loader.h>
#include <mach-o/fat.h>
#include <mach-o/swap.h>
#include <mach/machine.h> // For cpu_type_t, cpu_subtype_t

typedef struct {
    cpu_type_t cputype;
    cpu_subtype_t cpusubtype;
} CDArch;

@class CDMachOFile, CDSearchPathState;

extern NSString *CDNameForCPUType(cpu_type_t cputype, cpu_subtype_t cpusubtype);
extern CDArch CDArchFromName(NSString *name);
extern BOOL CDArchUses64BitABI(CDArch arch);

@interface CDFile : NSObject
{
    NSString *filename;
    NSData *data;
    NSUInteger archOffset;
    NSUInteger archSize;
    CDSearchPathState *searchPathState;
}

// Returns CDFatFile or CDMachOFile.
+ (id)fileWithData:(NSData *)someData filename:(NSString *)aFilename searchPathState:(CDSearchPathState *)aSearchPathState;
+ (id)fileWithData:(NSData *)someData archOffset:(NSUInteger)anOffset archSize:(NSUInteger)aSize filename:(NSString *)aFilename searchPathState:(CDSearchPathState *)aSearchPathState;

- (id)initWithData:(NSData *)someData archOffset:(NSUInteger)anOffset archSize:(NSUInteger)aSize filename:(NSString *)aFilename searchPathState:(CDSearchPathState *)aSearchPathState;

@property (readonly) NSString *filename;
@property (readonly) NSData *data;
@property (readonly) CDSearchPathState *searchPathState;

- (BOOL)bestMatchForLocalArch:(CDArch *)archPtr;
- (CDMachOFile *)machOFileWithArch:(CDArch)arch;

@end
