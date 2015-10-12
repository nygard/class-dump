// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDClassDumpVisitor.h"

#include <mach-o/arch.h>

#import "CDClassDump.h"
#import "CDObjectiveCProcessor.h"
#import "CDMachOFile.h"
#import "CDLCDylib.h"
#import "CDLCDylinker.h"
#import "CDLCEncryptionInfo.h"
#import "CDLCRunPath.h"
#import "CDLCSegment.h"
#import "CDLCSourceVersion.h"
#import "CDLCVersionMinimum.h"
#import "CDTypeController.h"

@implementation CDClassDumpVisitor
{
}

- (void)willBeginVisiting;
{
    [super willBeginVisiting];

    [self.classDump appendHeaderToString:self.resultString];

    if (self.classDump.hasObjectiveCRuntimeInfo && self.shouldShowStructureSection) {
        [self.classDump.typeController appendStructuresToString:self.resultString];
    }
}

- (void)didEndVisiting;
{
    [super didEndVisiting];

    [self writeResultToStandardOutput];
}

- (void)visitObjectiveCProcessor:(CDObjectiveCProcessor *)processor;
{
    CDMachOFile *machOFile = processor.machOFile;

    [self.resultString appendString:@"#pragma mark -\n\n"];
    [self.resultString appendString:@"//\n"];
    [self.resultString appendFormat:@"// File: %@\n", machOFile.filename];
    if (machOFile.UUID != nil) {
        [self.resultString appendFormat:@"// UUID: %@\n", [machOFile.UUID UUIDString]];
    }
    [self.resultString appendString:@"//\n"];
    [self.resultString appendFormat:@"//                           Arch: %@\n", CDNameForCPUType(machOFile.cputype, machOFile.cpusubtype)];

    if (machOFile.filetype == MH_DYLIB) {
        CDLCDylib *identifier = machOFile.dylibIdentifier;
        if (identifier != nil) {
            [self.resultString appendFormat:@"//                Current version: %@\n", identifier.formattedCurrentVersion];
            [self.resultString appendFormat:@"//          Compatibility version: %@\n", identifier.formattedCompatibilityVersion];
        }
    }
    
    if (machOFile.sourceVersion != nil)
        [self.resultString appendFormat:@"//                 Source version: %@\n", machOFile.sourceVersion.sourceVersionString];

    if (machOFile.minVersionMacOSX != nil) {
        [self.resultString appendFormat:@"//       Minimum Mac OS X version: %@\n", machOFile.minVersionMacOSX.minimumVersionString];
        [self.resultString appendFormat:@"//                    SDK version: %@\n", machOFile.minVersionMacOSX.SDKVersionString];
    }
    if (machOFile.minVersionIOS != nil) {
        [self.resultString appendFormat:@"//            Minimum iOS version: %@\n", machOFile.minVersionIOS.minimumVersionString];
        [self.resultString appendFormat:@"//                    SDK version: %@\n", machOFile.minVersionIOS.SDKVersionString];
    }

    if (processor.garbageCollectionStatus != nil) {
        [self.resultString appendString:@"//\n"];
        [self.resultString appendFormat:@"// Objective-C Garbage Collection: %@\n", processor.garbageCollectionStatus];
    }

    [machOFile.dyldEnvironment enumerateObjectsUsingBlock:^(CDLCDylinker *env, NSUInteger index, BOOL *stop){
        if (index == 0) {
            [self.resultString appendString:@"//\n"];
            [self.resultString appendFormat:@"//               dyld environment: %@\n", env.name];
        } else {
            [self.resultString appendFormat:@"//                                 %@\n", env.name];
        }
    }];

    if ([machOFile.runPathCommands count] > 0) {
        [self.resultString appendString:@"//\n"];
        for (CDLCRunPath *runPath in machOFile.runPathCommands) {
                [self.resultString appendFormat:@"//                       Run path: %@\n", runPath.path];
                [self.resultString appendFormat:@"//                               = %@\n", runPath.resolvedRunPath];
        }
    }

    if (machOFile.isEncrypted) {
        [self.resultString appendString:@"//         This file is encrypted:\n"];
        for (CDLoadCommand *loadCommand in machOFile.loadCommands) {
            if ([loadCommand isKindOfClass:[CDLCEncryptionInfo class]]) {
                CDLCEncryptionInfo *encryptionInfo = (CDLCEncryptionInfo *)loadCommand;

                [self.resultString appendFormat:@"//                                   cryptid: 0x%08x\n", encryptionInfo.cryptid];
                [self.resultString appendFormat:@"//                                  cryptoff: 0x%08x\n", encryptionInfo.cryptoff];
                [self.resultString appendFormat:@"//                                 cryptsize: 0x%08x\n", encryptionInfo.cryptsize];
            }
        }
    } else if (machOFile.hasProtectedSegments) {
        if (machOFile.canDecryptAllSegments) {
            [self.resultString appendString:@"//\n"];
            [self.resultString appendString:@"//     This file has protected segments, decrypting.\n"];
        } else {
            [self.resultString appendString:@"//\n"];
            [self.resultString appendString:@"//     This file has protected segments that can't be decrypted:\n"];
            [machOFile.loadCommands enumerateObjectsUsingBlock:^(CDLoadCommand *loadCommand, NSUInteger index, BOOL *stop){
                if ([loadCommand isKindOfClass:[CDLCSegment class]]) {
                    CDLCSegment *segment = (CDLCSegment *)loadCommand;
                    
                    if (segment.canDecrypt == NO) {
                        [self.resultString appendFormat:@"//         Load command %lu, segment encryption: %@\n",
                         index, CDSegmentEncryptionTypeName(segment.encryptionType)];
                    }
                }
            }];
        }
    }
    [self.resultString appendString:@"//\n\n"];
    
    if (!self.classDump.hasObjectiveCRuntimeInfo) {
        [self.resultString appendString:@"//\n"];
        [self.resultString appendString:@"// This file does not contain any Objective-C runtime information.\n"];
        [self.resultString appendString:@"//\n"];
    }
}

@end
