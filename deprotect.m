// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#include <stdio.h>
#include <libc.h>
#include <unistd.h>
#include <getopt.h>
#include <stdlib.h>

#import <Foundation/Foundation.h>
#import "NSString-Extensions.h"

#import "CDClassDump.h"
#import "CDMachOFile.h"

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

enum {
    CDFormatIvar = 0,
    CDFormatMethod = 1,
    CDFormatBalance = 2,
};

int main(int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    int ch;
    BOOL errorFlag = NO;

    struct option longopts[] = {
        { NULL, 0, NULL, 0 },
    };

    if (argc == 1) {
        print_usage();
        exit(0);
    }

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
        NSString *inputFile, *outputFile;
        CDFile *file;
        NSData *inputData;

        inputFile = [NSString stringWithFileSystemRepresentation:argv[0]];
        outputFile = [NSString stringWithFileSystemRepresentation:argv[1]];

        NSLog(@"inputFile: %@", inputFile);
        NSLog(@"outputFile: %@", outputFile);

        inputData = [[NSData alloc] initWithContentsOfMappedFile:inputFile];

        file = [CDFile fileWithData:inputData filename:inputFile searchPathState:nil];
        if (file == nil) {
            fprintf(stderr, "deprotect: Input file (%s) is neither a Mach-O file nor a fat archive.\n", [inputFile UTF8String]);
            exit(1);
        }

        if ([file isKindOfClass:[CDMachOFile class]]) {
            NSLog(@"file: %@", file);
            [(CDMachOFile *)file saveDeprotectedFileToPath:outputFile];
        } else {
            NSLog(@"Can only deprotect thin mach-o files at this point.");
        }

        [inputData release];
    }

    [pool release];

    return 0;
}
