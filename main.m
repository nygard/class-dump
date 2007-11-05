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
#import "CDFindMethodVisitor.h"
#import "CDClassDumpVisitor.h"
#import "CDMultiFileVisitor.h"
#import "CDMachOFile.h"
#import "CDFatFile.h"

void print_usage(void)
{
    fprintf(stderr,
            "class-dump %s\n"
            "Usage: class-dump [options] <mach-o-file>\n"
            "\n"
            "  where options are:\n"
            "        -a             show instance variable offsets\n"
            "        -A             show implementation addresses\n"
            "        --arch <arch>  choose a specific architecture from a universal binary (ppc, ppc7400, ppc64, i386, x86_64, etc.)\n"
            "        -C <regex>     only display classes matching regular expression\n"
            "        -f <str>       find string in method name\n"
            "        -H             generate header files in current directory, or directory specified with -o\n"
            "        -I             sort classes, categories, and protocols by inheritance (overrides -s)\n"
            "        -o <dir>       output directory used for -H\n"
            "        -r             recursively expand frameworks and fixed VM shared libraries\n"
            "        -s             sort classes and categories by name\n"
            "        -S             sort methods by name\n"
            "        -t             suppress header in output, for testing\n"
            "        --list-arches  list the arches in the file, then exit\n"
            //"        -x             generate XML output\n"
            ,
            [CLASS_DUMP_VERSION UTF8String]
       );
}

#define CD_OPT_ARCH 1
#define CD_OPT_LIST_ARCHES 2

int main(int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    CDClassDump *classDump;
    CDMultiFileVisitor *multiFileVisitor;
    BOOL shouldFind = NO;
    NSString *searchString = nil;
    BOOL shouldGenerateSeparateHeaders = NO;
    BOOL shouldListArches = NO;

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
        { "list-arches", no_argument, NULL, CD_OPT_LIST_ARCHES },
        { "suppress-header", no_argument, NULL, 't' },
        { NULL, 0, NULL, 0 },
    };

    if (argc == 1) {
        print_usage();
        exit(0);
    }

    classDump = [[[CDClassDump alloc] init] autorelease];
    multiFileVisitor = [[[CDMultiFileVisitor alloc] init] autorelease];
    [multiFileVisitor setClassDump:classDump];

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
                  [classDump setPreferredArchName:[NSString stringWithUTF8String:optarg]];
              }
          }
              break;

          case CD_OPT_LIST_ARCHES:
              shouldListArches = YES;
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
              shouldGenerateSeparateHeaders = YES;
              break;

          case 'I':
              [classDump setShouldSortClassesByInheritance:YES];
              break;

          case 'o':
              [multiFileVisitor setOutputPath:[NSString stringWithCString:optarg]];
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
        if (shouldListArches) {
            NSString *executablePath;

            executablePath = [CDClassDump executablePathForFilename:path];
            if (executablePath == nil) {
                printf("none\n");
            } else {
                id macho;

                macho = [CDMachOFile machOFileWithFilename:executablePath];
                if (macho == nil) {
                    printf("none\n");
                } else {
                    if ([macho isKindOfClass:[CDMachOFile class]]) {
                        printf("%s\n", [[macho archName] UTF8String]);
                    } else {
                        printf("%s\n", [[[macho archNames] componentsJoinedByString:@" "] UTF8String]);
                    }
                }
            }
        } else {
            if ([classDump processFilename:path] == YES) {
#if 0
                [classDump showHeader];
                [classDump showLoadCommands];
                exit(5);
#endif
                [classDump processObjectiveCSegments];
                [classDump registerStuff];

                if (shouldFind) {
                    CDFindMethodVisitor *visitor;

                    visitor = [[CDFindMethodVisitor alloc] init];
                    [visitor setClassDump:classDump];
                    [visitor setFindString:searchString];
                    [classDump recursivelyVisit:visitor];
                    [visitor release];
                } else if (shouldGenerateSeparateHeaders) {
                    [classDump recursivelyVisit:multiFileVisitor];
                } else {
                    CDClassDumpVisitor *visitor;

                    visitor = [[CDClassDumpVisitor alloc] init];
                    [visitor setClassDump:classDump];
                    [classDump recursivelyVisit:visitor];
                    [visitor release];
                }
            }
        }
    }

    [pool release];

    return 0;
}
