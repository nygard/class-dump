// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDFile.h"

#import "CDFatFile.h"
#import "CDMachOFile.h"

NSString *CDNameForCPUType(cpu_type_t cputype, cpu_subtype_t cpusubtype)
{
    const NXArchInfo *archInfo = NXGetArchInfoFromCpuType(cputype, cpusubtype);
    if (archInfo == NULL)
        return [NSString stringWithFormat:@"0x%x:0x%x", cputype, cpusubtype];

    return [NSString stringWithUTF8String:archInfo->name];
}

CDArch CDArchFromName(NSString *name)
{
    CDArch arch;

    arch.cputype = CPU_TYPE_ANY;
    arch.cpusubtype = 0;

    if (name == nil)
        return arch;

    const NXArchInfo *archInfo = NXGetArchInfoFromName([name UTF8String]);
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

#pragma mark -

@implementation CDFile
{
    NSString *filename;
    NSData *data;
    NSUInteger archOffset;
    NSUInteger archSize;
    CDSearchPathState *searchPathState;
}

+ (id)fileWithData:(NSData *)someData filename:(NSString *)aFilename searchPathState:(CDSearchPathState *)aSearchPathState;
{
    return [self fileWithData:someData archOffset:0 archSize:[someData length] filename:aFilename searchPathState:aSearchPathState];
}

+ (id)fileWithData:(NSData *)someData archOffset:(NSUInteger)anOffset archSize:(NSUInteger)aSize filename:(NSString *)aFilename searchPathState:(CDSearchPathState *)aSearchPathState;
{
    CDFatFile *aFatFile = nil;

    if (anOffset == 0)
        aFatFile = [[[CDFatFile alloc] initWithData:someData archOffset:anOffset archSize:aSize filename:aFilename searchPathState:aSearchPathState] autorelease];

    if (aFatFile == nil) {
        CDMachOFile *machOFile = [[[CDMachOFile alloc] initWithData:someData archOffset:anOffset archSize:aSize filename:aFilename searchPathState:aSearchPathState] autorelease];
        return machOFile;
    }

    return aFatFile;
}

- (id)init;
{
    [NSException raise:@"RejectUnusedImplementation" format:@"-initWithData: is the designated initializer"];
    return nil;
}

- (id)initWithData:(NSData *)someData archOffset:(NSUInteger)anOffset archSize:(NSUInteger)aSize filename:(NSString *)aFilename searchPathState:(CDSearchPathState *)aSearchPathState;
{
    if ((self = [super init])) {
        // Otherwise reading the magic number fails.
        if ([someData length] < 4) {
            [self release];
            return nil;
        }
        
        filename = [aFilename retain];
        data = [someData retain];
        archOffset = anOffset;
        archSize = aSize;
        searchPathState = [aSearchPathState retain];
    }

    return self;
}

- (void)dealloc;
{
    [filename release];
    [data release];
    [searchPathState release];

    [super dealloc];
}

#pragma mark -

@synthesize filename;
@synthesize data;
@synthesize archOffset;
@synthesize archSize;
@synthesize searchPathState;

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
