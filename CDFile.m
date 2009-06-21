//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2009 Steve Nygard.  All rights reserved.

#import "CDFile.h"

#import "CDFatFile.h"
#import "CDMachO32File.h"
#import "CDMachO64File.h"

NSString *CDNameForCPUType(cpu_type_t cputype, cpu_subtype_t cpusubtype)
{
    const NXArchInfo *archInfo;

    archInfo = NXGetArchInfoFromCpuType(cputype, cpusubtype);
    if (archInfo == NULL)
        return @"unknown";

    return [NSString stringWithUTF8String:archInfo->name];
}

@implementation CDFile

+ (id)fileWithData:(NSData *)someData;
{
    CDFatFile *aFatFile;

    aFatFile = [[[CDFatFile alloc] initWithData:someData] autorelease];
    if (aFatFile == nil) {
        CDMachOFile *machOFile;

        machOFile = [[[CDMachO32File alloc] initWithData:someData] autorelease];
        if (machOFile == nil)
            machOFile = [[[CDMachO64File alloc] initWithData:someData] autorelease];
        return machOFile;
    }

    return aFatFile;
}

- (id)initWithData:(NSData *)someData;
{
    if ([super init] == nil)
        return nil;

    filename = nil;
    data = [someData retain];
    offset = 0;

    return self;
}

- (void)dealloc;
{
    [filename release];
    [data release];

    [super dealloc];
}

- (NSString *)filename;
{
    return filename;
}

- (void)setFilename:(NSString *)newName;
{
    if (newName == filename)
        return;

    [filename release];
    filename = [newName retain];
}

- (NSUInteger)offset;
{
    return offset;
}

- (void)setOffset:(NSUInteger)newOffset;
{
    offset = newOffset;
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
