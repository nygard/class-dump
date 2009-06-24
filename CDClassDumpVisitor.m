// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import "CDClassDumpVisitor.h"

#include <mach-o/arch.h>

#import "NSArray-Extensions.h"
#import "CDClassDump.h"
#import "CDObjectiveC1Processor.h"
#import "CDMachOFile.h"
#import "CDOCProtocol.h"
#import "CDLCDylib.h"
#import "CDOCClass.h"
#import "CDOCCategory.h"
#import "CDSymbolReferences.h"

@implementation CDClassDumpVisitor

- (void)willBeginVisiting;
{
    [super willBeginVisiting];

    [classDump appendHeaderToString:resultString];

    if ([classDump containsObjectiveCData]) {
        [classDump appendStructuresToString:resultString symbolReferences:nil];
        //[resultString appendString:@"// [structures go here]\n"];
    } else {
        [resultString appendString:@"This file does not contain any Objective-C runtime information.\n"];
    }
}

- (void)didEndVisiting;
{
    [super didEndVisiting];

    [self writeResultToStandardOutput];
}

- (void)visitObjectiveCProcessor:(CDObjectiveC1Processor *)aProcessor;
{
    CDMachOFile *machOFile;
    const NXArchInfo *archInfo;

    machOFile = [aProcessor machOFile];

    [resultString appendString:@"/*\n"];
    [resultString appendFormat:@" * File: %@\n", [machOFile filename]];

    archInfo = NXGetArchInfoFromCpuType([machOFile cputype], [machOFile cpusubtype]);
    if (archInfo != NULL)
        [resultString appendFormat:@" * Arch: %s (%s)\n", archInfo->description, archInfo->name];

    if ([machOFile filetype] == MH_DYLIB) {
        CDLCDylib *identifier;

        identifier = [machOFile dylibIdentifier];
        if (identifier != nil)
            [resultString appendFormat:@" *       Current version: %@, Compatibility version: %@\n",
                          [identifier formattedCurrentVersion], [identifier formattedCompatibilityVersion]];
    }

    if ([machOFile hasProtectedSegments]) {
        [resultString appendString:@" *       (This file has protected segments, decrypting.)\n"];
    }
    [resultString appendString:@" */\n\n"];
}

@end
