// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDFile.h"

#import "CDFatFile.h"
#import "CDMachO32File.h"
#import "CDMachO64File.h"

NSString *CDNameForCPUType(cpu_type_t cputype, cpu_subtype_t cpusubtype)
{
    const NXArchInfo *archInfo;

    archInfo = NXGetArchInfoFromCpuType(cputype, cpusubtype);
    if (archInfo == NULL)
        return [NSString stringWithFormat:@"0x%x:0x%x", cputype, cpusubtype];

    return [NSString stringWithUTF8String:archInfo->name];
}

CDArch CDArchFromName(NSString *name)
{
    const NXArchInfo *archInfo;
    CDArch arch;

    arch.cputype = CPU_TYPE_ANY;
    arch.cpusubtype = 0;

    if (name == nil)
        return arch;

    archInfo = NXGetArchInfoFromName([name UTF8String]);
    if (archInfo == NULL) {
        NSScanner *scanner;
        NSString *ignore;

        scanner = [[NSScanner alloc] initWithString:name];
        if ([scanner scanHexInt:(uint32_t *)&arch.cputype]
            && [scanner scanString:@":" intoString:&ignore]
            && [scanner scanHexInt:(uint32_t *)&arch.cpusubtype]) {
            // Great!
            //NSLog(@"scanned 0x%08x : 0x%08x from '%@'", arch.cputype, arch.cpusubtype, name);
        } else {
            arch.cputype = CPU_TYPE_ANY;
            arch.cpusubtype = 0;
        }

        [scanner release];
    } else {
        arch.cputype = archInfo->cputype;
        arch.cpusubtype = archInfo->cpusubtype;
    }

    return arch;
}

BOOL CDArchUses64BitABI(CDArch arch)
{
    return (arch.cputype & CPU_ARCH_MASK) == CPU_ARCH_ABI64;
}

@implementation CDFile

+ (id)fileWithData:(NSData *)someData filename:(NSString *)aFilename searchPathState:(CDSearchPathState *)aSearchPathState;
{
    return [self fileWithData:someData offset:0 filename:aFilename searchPathState:aSearchPathState];
}

+ (id)fileWithData:(NSData *)someData offset:(NSUInteger)anOffset filename:(NSString *)aFilename searchPathState:(CDSearchPathState *)aSearchPathState;
{
    CDFatFile *aFatFile = nil;

    if (anOffset == 0)
        aFatFile = [[[CDFatFile alloc] initWithData:someData offset:anOffset filename:aFilename searchPathState:aSearchPathState] autorelease];

    if (aFatFile == nil) {
        CDMachOFile *machOFile;

        machOFile = [[[CDMachO32File alloc] initWithData:someData offset:anOffset filename:aFilename searchPathState:aSearchPathState] autorelease];
        if (machOFile == nil)
            machOFile = [[[CDMachO64File alloc] initWithData:someData offset:anOffset filename:aFilename searchPathState:aSearchPathState] autorelease];
        return machOFile;
    }

    return aFatFile;
}

- (id)init;
{
    [NSException raise:@"RejectUnusedImplementation" format:@"-initWithData: is the designated initializer"];
    return nil;
}

- (id)initWithData:(NSData *)someData offset:(NSUInteger)anOffset filename:(NSString *)aFilename searchPathState:(CDSearchPathState *)aSearchPathState;
{
    if ([super init] == nil)
        return nil;

    // Otherwise reading the magic number fails.
    if ([someData length] < 4) {
        [self release];
        return nil;
    }

    filename = [aFilename retain];
    data = [someData retain];
    offset = anOffset;
    searchPathState = [aSearchPathState retain];

    return self;
}

- (void)dealloc;
{
    [filename release];
    [data release];
    [searchPathState release];

    [super dealloc];
}

- (NSString *)filename;
{
    return filename;
}

- (NSData *)data;
{
    return data;
}

- (NSUInteger)offset;
{
    return offset;
}

- (void)setOffset:(NSUInteger)newOffset;
{
    offset = newOffset;
}

- (CDSearchPathState *)searchPathState;
{
    return searchPathState;
}

- (BOOL)bestMatchForLocalArch:(CDArch *)archPtr;
{
    if (archPtr != NULL) {
        archPtr->cputype = CPU_TYPE_ANY;
        archPtr->cpusubtype = 0;
    }

    return YES;
}

- (CDMachOFile *)machOFileWithArch:(CDArch)arch;
{
    return nil;
}

@end
