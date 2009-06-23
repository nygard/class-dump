// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

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
    return [self fileWithData:someData offset:0];
}

+ (id)fileWithData:(NSData *)someData offset:(NSUInteger)anOffset;
{
    CDFatFile *aFatFile = nil;

    if (anOffset == 0)
        aFatFile = [[[CDFatFile alloc] initWithData:someData offset:anOffset] autorelease];

    if (aFatFile == nil) {
        CDMachOFile *machOFile;

        machOFile = [[[CDMachO32File alloc] initWithData:someData offset:anOffset] autorelease];
        if (machOFile == nil)
            machOFile = [[[CDMachO64File alloc] initWithData:someData offset:anOffset] autorelease];
        return machOFile;
    }

    return aFatFile;
}

- (id)init;
{
    [NSException raise:@"RejectUnusedImplementation" format:@"-initWithData: is the designated initializer"];
    return nil;
}

- (id)initWithData:(NSData *)someData offset:(NSUInteger)anOffset;
{
    if ([super init] == nil)
        return nil;

    filename = nil;
    data = [someData retain];
    offset = anOffset;

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
