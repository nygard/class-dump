//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2007  Steve Nygard

#include <stdio.h>
#include <libc.h>
#include <unistd.h>
#include <getopt.h>
#include <stdlib.h>
#include <mach-o/arch.h>

#import <Foundation/Foundation.h>
#import "NSString-Extensions.h"

#import "CDClassDump.h"

void print_usage(void)
{
    fprintf(stderr,
            "class-dump %s\n"
            "Usage: class-dump [options] <mach-o-file>\n"
            "\n"
            "  where options are:\n"
            "        -a             show instance variable offsets\n"
            "        -A             show implementation addresses\n"
            "        --arch <arch>  choose a specific architecture from a universal binary (ppc, i386, etc.)\n"
            "        -C <regex>     only display classes matching regular expression\n"
            "        -f <str>       find string\n"
            "        -H             generate header files in current directory, or directory specified with -o\n"
            "        -I             sort classes, categories, and protocols by inheritance (overrides -s)\n"
            "        -o <dir>       output directory used for -H\n"
            "        -r             recursively expand frameworks and fixed VM shared libraries\n"
            "        -s             sort classes and categories by name\n"
            "        -S             sort methods by name\n"
            "        -t             suppress header in output, for testing\n"
            "        -x             generate XML output\n"
            ,
            [CLASS_DUMP_VERSION UTF8String]
       );
}

#define CD_OPT_ARCH 1

int main(int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    CDClassDump *classDump;
    BOOL shouldFind = NO;
    NSString *searchString = nil;

    int ch;
    BOOL errorFlag = NO;

    struct option longopts[] = {
        { "show-ivar-offsets", no_argument, NULL, 'a' },
        { "show-imp-addr", no_argument, NULL, 'A' },
        { "match", required_argument, NULL, 'C' },
        { "find", required_argument, NULL, 'f' },
        { "generate-multiple-files", no_argument, NULL, 'H' },
        { "sort-by-inheritance", no_argument, NULL, 'I' },
        { "output-dir", required_argument, NULL, 'o' },
        { "recursive", no_argument, NULL, 'r' },
        { "sort", no_argument, NULL, 's' },
        { "sort-methods", no_argument, NULL, 'S' },
        { "arch", required_argument, NULL, CD_OPT_ARCH },
        { "suppress-header", no_argument, NULL, 't' },
        { "generate-xml", no_argument, NULL, 'x' },
        { NULL, 0, NULL, 0 },
    };

    if (argc == 1) {
        print_usage();
        exit(2);
    }

    classDump = [[[CDClassDump alloc] init] autorelease];

    while ( (ch = getopt_long(argc, argv, "aAC:f:HIo:rRsStx", longopts, NULL)) != -1) {
        switch (ch) {
          case CD_OPT_ARCH:
          {
              const NXArchInfo *archInfo;

              archInfo = NXGetArchInfoFromName(optarg);
              if (archInfo == NULL) {
                  fprintf(stderr, "class-dump: Unknown arch %s\n\n", optarg);
                  errorFlag = YES;
              } else {
                  [classDump setPreferredCPUType:archInfo->cputype];
              }
          }
              break;

          case 'a':
              [classDump setShouldShowIvarOffsets:YES];
              break;

          case 'A':
              [classDump setShouldShowMethodAddresses:YES];
              break;

          case 'C':
          {
              NSString *errorMessage;

              if ([classDump setRegex:optarg errorMessage:&errorMessage] == NO) {
                  fprintf(stderr, "class-dump: Error with regex: '%s'\n\n", [errorMessage UTF8String]);
                  errorFlag = YES;
              }
              // Last one wins now.
              break;
          }

          case 'f':
          {
              shouldFind = YES;
              searchString = [NSString stringWithUTF8String:optarg];
              break;
          }

          case 'H':
              [classDump setShouldGenerateSeparateHeaders:YES];
              break;

          case 'I':
              [classDump setShouldSortClassesByInheritance:YES];
              break;

          case 'o':
              [classDump setOutputPath:[NSString stringWithCString:optarg]];
              break;

          case 'r':
              [classDump setShouldProcessRecursively:YES];
              break;

          case 's':
              [classDump setShouldSortClasses:YES];
              break;

          case 'S':
              [classDump setShouldSortMethods:YES];
              break;

          case 't':
              [classDump setShouldShowHeader:NO];
              break;

          case 'x':
              [classDump setShouldGenerateXML:YES];
              break;

          case '?':
          default:
              errorFlag = YES;
              break;
        }
    }

    if (errorFlag == YES) {
        print_usage();
        exit(2);
    }

    // TODO (2005-07-27): Maybe add a flag to test whether the file has Objective-C segments, and return a different exit code.
    if (optind < argc) {
        NSString *path;

        path = [NSString stringWithFileSystemRepresentation:argv[optind]];
        if ([classDump processFilename:path] == YES) {
#if 1
            [classDump processObjectiveCSegments];

            if (shouldFind) {
                [classDump find:searchString];
            } else
                [classDump generateOutput];
#else
            [classDump showHeader];
            [classDump showLoadCommands];
#endif
        }
    }

    [pool release];

    return 0;
}
