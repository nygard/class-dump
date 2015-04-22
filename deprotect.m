// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#include <stdio.h>
#include <libc.h>
#include <unistd.h>
#include <getopt.h>
#include <stdlib.h>
#include <sysexits.h>
#include <mach-o/arch.h>

#import "CDClassDump.h"
#import "CDMachOFile.h"
#import "CDFatFile.h"
#import "CDLoadCommand.h"
#import "CDLCSegment.h"

void print_usage(void)
{
    fprintf(stderr,
            "deprotect %s\n"
            "Usage: deprotect [options] <input file> <output file>\n"
            "\n"
            "  where options are:\n"
            "        --arch <arch>  choose a specific architecture from a universal binary (ppc, ppc64, i386, x86_64, armv6, armv7, armv7s, arm64)\n"
            ,
            CLASS_DUMP_VERSION
       );
}

BOOL saveDeprotectedFileToPath(CDMachOFile *file, NSString *path)
{
    BOOL hasProtectedSegments = NO;
    NSMutableData *mdata = [[NSMutableData alloc] initWithData:file.data];
    for (CDLoadCommand *command in file.loadCommands) {
        if ([command isKindOfClass:[CDLCSegment class]]) {
            CDLCSegment *segment = (CDLCSegment *)command;
            
            if (segment.isProtected) {
                hasProtectedSegments = YES;
                NSRange segmentRange = NSMakeRange([segment fileoff], [segment filesize]);
                NSUInteger flagOffset;
                
                NSData *decryptedData = [segment decryptedData];
                NSCParameterAssert([decryptedData length] == segmentRange.length);
                
                [mdata replaceBytesInRange:segmentRange withBytes:[decryptedData bytes]];
                if (segment.machOFile.uses64BitABI) {
                    flagOffset = [segment commandOffset] + offsetof(struct segment_command_64, flags);
                } else {
                    flagOffset = [segment commandOffset] + offsetof(struct segment_command, flags);
                }
                
                CDMachOFileDataCursor *cursor = [[CDMachOFileDataCursor alloc] initWithFile:file offset:flagOffset];
                uint32_t flags = [cursor readInt32];
                if (flags != [segment flags]) {
                    fprintf(stderr, "Internal Error: flags (0x%x) does not match segment flags (0x%x).\n", flags, [segment flags]);
                    exit(EX_SOFTWARE);
                }
                flags &= ~SG_PROTECTED_VERSION_1;
                
                if (file.byteOrder == CDByteOrder_BigEndian) {
                    OSWriteBigInt32([mdata mutableBytes], flagOffset, flags);
                } else {
                    OSWriteLittleInt32([mdata mutableBytes], flagOffset, flags);
                }
            }
        }
    }
    
    if (hasProtectedSegments) {
        [mdata writeToFile:path atomically:NO];
    }
    
    return hasProtectedSegments;
}

int main(int argc, char *argv[])
{
    @autoreleasepool {
        if (argc == 1) {
            print_usage();
            exit(EX_OK);
        }
        
        int ch;
        BOOL errorFlag = NO;
        CDArch targetArch = {CPU_TYPE_ANY, CPU_TYPE_ANY};
        
        struct option longopts[] = {
            { "arch", required_argument, NULL, 'a' },
            { NULL,   0,                 NULL, 0 },
        };
        
        while ( (ch = getopt_long(argc, argv, "a:", longopts, NULL)) != -1) {
            switch (ch) {
                case 'a': {
                    NSString *name = [NSString stringWithUTF8String:optarg];
                    targetArch = CDArchFromName(name);
                    if (targetArch.cputype == CPU_TYPE_ANY) {
                        fprintf(stderr, "Error: Unknown arch %s\n\n", optarg);
                        errorFlag = YES;
                    }
                    break;
                }
                case '?':
                default:
                    errorFlag = YES;
                    break;
            }
        }
        
        argc -= optind;
        argv += optind;

        if (errorFlag || argc < 2) {
            print_usage();
            exit(EX_USAGE);
        }
        
        {
            NSString *inputFile = [NSString stringWithFileSystemRepresentation:argv[0]];
            NSString *outputFile = [NSString stringWithFileSystemRepresentation:argv[1]];
            
            CDFile *file = [CDFile fileWithContentsOfFile:inputFile searchPathState:nil];
            if (file == nil) {
                fprintf(stderr, "Error: input file is neither a Mach-O file nor a fat archive.\n");
                exit(EX_DATAERR);
            }
            
            CDMachOFile *thinFile = nil;
            if ([file isKindOfClass:[CDMachOFile class]]) {
                thinFile = (CDMachOFile *)file;
            } else if ([file isKindOfClass:[CDFatFile class]]) {
                if (targetArch.cputype == CPU_TYPE_ANY) {
                    if ([file bestMatchForLocalArch:&targetArch] == NO) {
                        fprintf(stderr, "Internal Error: Couldn't get local architecture.\n");
                        exit(EX_SOFTWARE);
                    }
                }
                thinFile = [(CDFatFile *)file machOFileWithArch:targetArch];
                if (!thinFile) {
                    const NXArchInfo *arhcInfo = NXGetArchInfoFromCpuType(targetArch.cputype, targetArch.cpusubtype);
                    fprintf(stderr, "Error: input file does not contain the '%s' arch.\n", arhcInfo->name);
                    exit(EX_DATAERR);
                }
            } else {
                fprintf(stderr, "Internal Error: file is neither a CDFatFile nor a CDMachOFile instance.\n");
                exit(EX_SOFTWARE);
            }
            
            BOOL hasProtectedSegments = saveDeprotectedFileToPath(thinFile, outputFile);
            if (!hasProtectedSegments) {
                const NXArchInfo *arhcInfo = NXGetArchInfoFromCpuType(targetArch.cputype, targetArch.cpusubtype);
                fprintf(stderr, "Error: input file (%s arch) is not protected.\n", arhcInfo->name);
                exit(EX_DATAERR);
            }
        }
    }

    return 0;
}
