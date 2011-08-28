// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2011 Steve Nygard.

#import "CDClassDumpVisitor.h"

#include <mach-o/arch.h>

#import "NSArray-Extensions.h"
#import "CDClassDump.h"
#import "CDObjectiveCProcessor.h"
#import "CDMachOFile.h"
#import "CDOCProtocol.h"
#import "CDLCDylib.h"
#import "CDLCDylinker.h"
#import "CDLCEncryptionInfo.h"
#import "CDLCRunPath.h"
#import "CDLCSegment.h"
#import "CDLCVersionMinimum.h"
#import "CDOCClass.h"
#import "CDOCCategory.h"
#import "CDSymbolReferences.h"
#import "CDTypeController.h"

@implementation CDClassDumpVisitor

- (void)willBeginVisiting;
{
    [super willBeginVisiting];

    [classDump appendHeaderToString:resultString];

    if (classDump.hasObjectiveCRuntimeInfo) {
        [[classDump typeController] appendStructuresToString:resultString symbolReferences:nil];
    }
}

- (void)didEndVisiting;
{
    [super didEndVisiting];

    [self writeResultToStandardOutput];
}

- (void)visitObjectiveCProcessor:(CDObjectiveCProcessor *)aProcessor;
{
    CDMachOFile *machOFile = [aProcessor machOFile];

    [resultString appendString:@"#pragma mark -\n\n"];
    [resultString appendString:@"/*\n"];
    [resultString appendFormat:@" * File: %@\n", [machOFile filename]];
    [resultString appendFormat:@" * UUID: %@\n", [machOFile uuidString]];

    const NXArchInfo *archInfo = NXGetArchInfoFromCpuType([machOFile cputypePlusArchBits], [machOFile cpusubtype]);
    //archInfo = [machOFile archInfo];
    if (archInfo == NULL)
        [resultString appendFormat:@" * Arch: cputype: 0x%x, cpusubtype: 0x%x\n", [machOFile cputype], [machOFile cpusubtype]];
    else
        [resultString appendFormat:@" * Arch: %s (%s)\n", archInfo->description, archInfo->name];

    if ([machOFile filetype] == MH_DYLIB) {
        CDLCDylib *identifier = [machOFile dylibIdentifier];
        if (identifier != nil)
            [resultString appendFormat:@" *       Current version: %@, Compatibility version: %@\n",
                          [identifier formattedCurrentVersion], [identifier formattedCompatibilityVersion]];
    }

    if (machOFile.minVersionMacOSX != nil) 
        [resultString appendFormat:@" *       Minimum Mac OS X version: %@\n", machOFile.minVersionMacOSX.minimumVersionString];
    if (machOFile.minVersionIOS != nil) 
        [resultString appendFormat:@" *       Minimum iOS version: %@\n", machOFile.minVersionIOS.minimumVersionString];

    [resultString appendFormat:@" *\n"];
    if (aProcessor.garbageCollectionStatus != nil)
        [resultString appendFormat:@" *       Objective-C Garbage Collection: %@\n", aProcessor.garbageCollectionStatus];
    
    if ([machOFile.dyldEnvironment count] > 0) {
        BOOL first = YES;
        for (CDLCDylinker *env in machOFile.dyldEnvironment) {
            if (first) {
                [resultString appendFormat:@" *       dyld environment: %@\n", env.name];
                first = NO;
            } else {
                [resultString appendFormat:@" *                         %@\n", env.name];
            }
        }
    }

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
    
    if (!classDump.hasObjectiveCRuntimeInfo) {
        [resultString appendString:@"//\n"];
        [resultString appendString:@"// This file does not contain any Objective-C runtime information.\n"];
        [resultString appendString:@"//\n"];
    }
}

@end
