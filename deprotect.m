// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#include <stdio.h>
#include <libc.h>
#include <unistd.h>
#include <getopt.h>
#include <stdlib.h>

#import <Foundation/Foundation.h>

#import "CDClassDump.h"
#import "CDMachOFile.h"
#import "CDLoadCommand.h"
#import "CDLCSegment.h"
#import "CDLCSegment64.h"

void print_usage(void)
{
    fprintf(stderr,
            "deprotect %s\n"
            "Usage: deprotect [options] <input file> <output file>\n"
            "\n"
            "  where options are:\n"
            "        (none)\n"
            ,
            CLASS_DUMP_VERSION
       );
}

void saveDeprotectedFileToPath(CDMachOFile *file, NSString *path)
{
    NSMutableData *mdata = [[NSMutableData alloc] initWithData:file.data];
    for (CDLoadCommand *command in file.loadCommands) {
        if ([command isKindOfClass:[CDLCSegment class]]) {
            CDLCSegment *segment = (CDLCSegment *)command;
            
            if (segment.isProtected) {
                NSRange range;
                NSUInteger flagOffset;
                
                NSLog(@"segment is protected: %@", segment);
                range.location = [segment fileoff];
                range.length = [segment filesize];
                
                NSData *decryptedData = [segment decryptedData];
                NSCParameterAssert([decryptedData length] == range.length);
                
                [mdata replaceBytesInRange:range withBytes:[decryptedData bytes]];
                if ([segment isKindOfClass:[CDLCSegment64 class]]) {
                    flagOffset = [segment commandOffset] + offsetof(struct segment_command_64, flags);
                } else {
                    flagOffset = [segment commandOffset] + offsetof(struct segment_command, flags);
                }
                
                // TODO (2009-07-10): Needs to be endian-neutral
                uint32_t flags = OSReadLittleInt32([mdata mutableBytes], flagOffset);
                NSLog(@"old flags: %08x", flags);
                NSLog(@"segment flags: %08x", [segment flags]);
                flags &= ~SG_PROTECTED_VERSION_1;
                NSLog(@"new flags: %08x", flags);
                
                OSWriteLittleInt32([mdata mutableBytes], flagOffset, flags);
            }
        }
    }
    
    [mdata writeToFile:path atomically:NO];
    
    [mdata release];
}

int main(int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    struct option longopts[] = {
        { NULL, 0, NULL, 0 },
    };

    if (argc == 1) {
        print_usage();
        exit(0);
    }
    
    BOOL errorFlag = NO;
    int ch;

    while ( (ch = getopt_long(argc, argv, "", longopts, NULL)) != -1) {
        switch (ch) {
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
        exit(2);
    }

    {
        NSString *inputFile = [NSString stringWithFileSystemRepresentation:argv[0]];
        NSString *outputFile = [NSString stringWithFileSystemRepresentation:argv[1]];

        NSLog(@"inputFile: %@", inputFile);
        NSLog(@"outputFile: %@", outputFile);

        NSData *inputData = [[NSData alloc] initWithContentsOfMappedFile:inputFile];

        CDFile *file = [CDFile fileWithData:inputData filename:inputFile searchPathState:nil];
        if (file == nil) {
            fprintf(stderr, "deprotect: Input file (%s) is neither a Mach-O file nor a fat archive.\n", [inputFile UTF8String]);
            exit(1);
        }

        if ([file isKindOfClass:[CDMachOFile class]]) {
            NSLog(@"file: %@", file);
            saveDeprotectedFileToPath((CDMachOFile *)file, outputFile);
        } else {
            NSLog(@"Can only deprotect thin mach-o files at this point.");
        }

        [inputData release];
    }

    [pool release];

    return 0;
}
