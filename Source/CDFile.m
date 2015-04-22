// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDFile.h"

#include <mach-o/arch.h>
#import "CDFatFile.h"
#import "CDMachOFile.h"
#import "CDSearchPathState.h"

NSString *CDImportNameForPath(NSString *path)
{
    NSString *name = [path lastPathComponent];
    
    // Remove all extensions (make sure extensions like .a.dylib are covered)
    NSString *nameWithExtensions = name;
    for (NSInteger i = ([nameWithExtensions length] - 1); i >= 0; i--) {
        if ([nameWithExtensions characterAtIndex:i] == '.')
            name = [name substringToIndex:i];
    }
    
    NSString *libPrefix = @"lib";
    if ([name hasPrefix:libPrefix])
        name = [name substringFromIndex:[libPrefix length]];
    return name;
}

NSString *CDNameForCPUType(cpu_type_t cputype, cpu_subtype_t cpusubtype)
{
    const NXArchInfo *archInfo = NXGetArchInfoFromCpuType(cputype, cpusubtype);
    if (archInfo != NULL)
        return [NSString stringWithUTF8String:archInfo->name];

    // Special cases until the built-in function recognizes these.
    switch (cputype) {
        case CPU_TYPE_ARM: {
            switch (cpusubtype) {
                case 11: return @"armv7s"; // Not recognized in 10.8.4
            }
            break;
        }
        case CPU_TYPE_ARM | CPU_ARCH_ABI64: {
            switch (cpusubtype) {
                case CPU_SUBTYPE_ARM_ALL: return @"arm64"; // Not recognized in 10.8.4
            }
            break;
        }

        default: break;
    }

    return [NSString stringWithFormat:@"0x%x:0x%x", cputype, cpusubtype];
}

CDArch CDArchFromName(NSString *name)
{
    CDArch arch;

    arch.cputype    = CPU_TYPE_ANY;
    arch.cpusubtype = 0;

    if (name == nil)
        return arch;

    const NXArchInfo *archInfo = NXGetArchInfoFromName([name UTF8String]);
    if (archInfo == NULL) {
        if ([name isEqualToString:@"armv7s"]) { // Not recognized in 10.8.4
            arch.cputype    = CPU_TYPE_ARM;
            arch.cpusubtype = 11;
        } else if ([name isEqualToString:@"arm64"]) { // Not recognized in 10.8.4
            arch.cputype    = CPU_TYPE_ARM | CPU_ARCH_ABI64;
            arch.cpusubtype = CPU_SUBTYPE_ARM_ALL;
        } else {
            NSString *ignore;
            
            NSScanner *scanner = [[NSScanner alloc] initWithString:name];
            if ([scanner scanHexInt:(uint32_t *)&arch.cputype]
                && [scanner scanString:@":" intoString:&ignore]
                && [scanner scanHexInt:(uint32_t *)&arch.cpusubtype]) {
                // Great!
                //NSLog(@"scanned 0x%08x : 0x%08x from '%@'", arch.cputype, arch.cpusubtype, name);
            } else {
                arch.cputype    = CPU_TYPE_ANY;
                arch.cpusubtype = 0;
            }
        }
    } else {
        arch.cputype    = archInfo->cputype;
        arch.cpusubtype = archInfo->cpusubtype;
    }

    return arch;
}

BOOL CDArchUses64BitABI(CDArch arch)
{
    return (arch.cputype & CPU_ARCH_ABI64) == CPU_ARCH_ABI64;
}

BOOL CDArchUses64BitLibraries(CDArch arch)
{
    return (arch.cpusubtype & CPU_SUBTYPE_LIB64) == CPU_SUBTYPE_LIB64;
}

#pragma mark -

@interface CDFile ()
@end

#pragma mark -

@implementation CDFile
{
    NSString *_filename;
    NSData *_data;
    CDSearchPathState *_searchPathState;
}

// Returns CDFatFile or CDMachOFile
+ (id)fileWithContentsOfFile:(NSString *)filename searchPathState:(CDSearchPathState *)searchPathState;
{
    NSData *data = [NSData dataWithContentsOfMappedFile:filename];
    CDFatFile *fatFile = [[CDFatFile alloc] initWithData:data filename:filename searchPathState:searchPathState];
    if (fatFile != nil)
        return fatFile;
    
    CDMachOFile *machOFile = [[CDMachOFile alloc] initWithData:data filename:filename searchPathState:searchPathState];
    return machOFile;
}

- (id)initWithData:(NSData *)data filename:(NSString *)filename searchPathState:(CDSearchPathState *)searchPathState;
{
    if ((self = [super init])) {
        // Otherwise reading the magic number fails.
        if ([data length] < 4) {
            return nil;
        }
        
        _filename        = filename;
        _data            = data;
        _searchPathState = searchPathState;
    }

    return self;
}

#pragma mark -

// Return YES on success.  If oArchPtr is not NULL, return the best match.
// Return NO on failure, oArchPtr is untouched.

- (BOOL)bestMatchForLocalArch:(CDArch *)oArchPtr;
{
    const NXArchInfo *archInfo = NXGetLocalArchInfo();
    if (archInfo == NULL)
        return NO;
    
    CDArch arch = { archInfo->cputype, archInfo->cpusubtype };
    
    if ([self bestMatchForArch:&arch]) {
        if (oArchPtr != NULL)
            *oArchPtr = arch;
        return YES;
    }
    
    return NO;
}

- (BOOL)bestMatchForArch:(CDArch *)ioArchPtr;
{
    return NO;
}

- (CDMachOFile *)machOFileWithArch:(CDArch)arch;
{
    return nil;
}

- (NSString *)architectureNameDescription;
{
    return nil;
}

@end
