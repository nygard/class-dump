//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2009 Steve Nygard.  All rights reserved.

#import "CDFile.h"

#import "CDFatFile.h"
#import "CDMachOFile.h"

NSString *CDNameForCPUType(cpu_type_t cputype, cpu_subtype_t cpusubtype)
{
    const NXArchInfo *archInfo;

    archInfo = NXGetArchInfoFromCpuType(cputype, cpusubtype);
    if (archInfo == NULL)
        return @"unknown";

    return [NSString stringWithUTF8String:archInfo->name];
}

@implementation CDFile

+ (id)fileWithData:(NSData *)data;
{
    CDFatFile *aFatFile;

    aFatFile = [[[CDFatFile alloc] initWithData:data] autorelease];
    if (aFatFile == nil) {
        return [[[CDMachOFile alloc] initWithData:data] autorelease];
    }

    return aFatFile;
}

- (id)initWithData:(NSData *)data;
{
    if ([super init] == nil)
        return nil;

    return self;
}

- (NSString *)bestMatchForLocalArch;
{
    return nil;
}

- (CDMachOFile *)machOFileWithArchName:(NSString *)name;
{
    return nil;
}

// ** CDMachO32File
// CDMachO32BitFile
// CD32BitMachOFile

// ** CDMachO64File)
// CDMachO64BitFile
// CD64BitMachOFile

@end
