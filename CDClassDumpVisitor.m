// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDClassDumpVisitor.h"

#include <mach-o/arch.h>

#import "NSArray-Extensions.h"
#import "CDClassDump.h"
#import "CDObjectiveCProcessor.h"
#import "CDMachOFile.h"
#import "CDOCProtocol.h"
#import "CDLCDylib.h"
#import "CDLCEncryptionInfo.h"
#import "CDLCRunPath.h"
#import "CDLCSegment.h"
#import "CDOCClass.h"
#import "CDOCCategory.h"
#import "CDSymbolReferences.h"
#import "CDTypeController.h"

@implementation CDClassDumpVisitor

- (void)willBeginVisiting;
{
    [super willBeginVisiting];

    [classDump appendHeaderToString:resultString];

    if ([classDump containsObjectiveCData] || [classDump hasEncryptedFiles]) {
        [[classDump typeController] appendStructuresToString:resultString symbolReferences:nil];
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

- (void)visitObjectiveCProcessor:(CDObjectiveCProcessor *)aProcessor;
{
    CDMachOFile *machOFile;
    const NXArchInfo *archInfo;

    machOFile = [aProcessor machOFile];

    [resultString appendString:@"#pragma mark -\n\n"];
    [resultString appendString:@"/*\n"];
    [resultString appendFormat:@" * File: %@\n", [machOFile filename]];
    [resultString appendFormat:@" * UUID: %@\n", [machOFile uuidString]];

    archInfo = NXGetArchInfoFromCpuType([machOFile cputypePlusArchBits], [machOFile cpusubtype]);
    //archInfo = [machOFile archInfo];
    if (archInfo == NULL)
        [resultString appendFormat:@" * Arch: cputype: 0x%x, cpusubtype: 0x%x\n", [machOFile cputype], [machOFile cpusubtype]];
    else
        [resultString appendFormat:@" * Arch: %s (%s)\n", archInfo->description, archInfo->name];

    if ([machOFile filetype] == MH_DYLIB) {
        CDLCDylib *identifier;

        identifier = [machOFile dylibIdentifier];
        if (identifier != nil)
            [resultString appendFormat:@" *       Current version: %@, Compatibility version: %@\n",
                          [identifier formattedCurrentVersion], [identifier formattedCompatibilityVersion]];
    }

    [resultString appendFormat:@" *\n"];
    [resultString appendFormat:@" *       Objective-C Garbage Collection: %@\n", [aProcessor garbageCollectionStatus]];

    for (CDLoadCommand *loadCommand in [machOFile loadCommands]) {
        if ([loadCommand isKindOfClass:[CDLCRunPath class]]) {
            CDLCRunPath *runPath = (CDLCRunPath *)loadCommand;

            [resultString appendFormat:@" *       Run path: %@\n", [runPath path]];
            [resultString appendFormat:@" *               = %@\n", [runPath resolvedRunPath]];
        }
    }

    if ([machOFile isEncrypted]) {
        [resultString appendString:@" *       This file is encrypted:\n"];
        for (CDLoadCommand *loadCommand in [machOFile loadCommands]) {
            if ([loadCommand isKindOfClass:[CDLCEncryptionInfo class]]) {
                CDLCEncryptionInfo *encryptionInfo = (CDLCEncryptionInfo *)loadCommand;

                [resultString appendFormat:@" *           cryptid: 0x%08x, cryptoff: 0x%08x, cryptsize: 0x%08x\n",
                              [encryptionInfo cryptid], [encryptionInfo cryptoff], [encryptionInfo cryptsize]];
            }
        }
    } else if ([machOFile hasProtectedSegments]) {
        if ([machOFile canDecryptAllSegments]) {
            [resultString appendString:@" *       This file has protected segments, decrypting.\n"];
        } else {
            NSUInteger index = 0;

            [resultString appendString:@" *       This file has protected segments that can't be decrypted:\n"];
            for (CDLoadCommand *loadCommand in [machOFile loadCommands]) {
                if ([loadCommand isKindOfClass:[CDLCSegment class]]) {
                    CDLCSegment *segment = (CDLCSegment *)loadCommand;

                    if ([segment canDecrypt] == NO) {
                        [resultString appendFormat:@" *           Load command %u, segment encryption: %@\n",
                                      index, CDSegmentEncryptionTypeName([segment encryptionType])];
                    }
                }

                index++;
            }
        }
    }
    [resultString appendString:@" */\n\n"];
}

@end
