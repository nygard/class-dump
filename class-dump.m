// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

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
#import "CDFile.h"
#import "CDMachOFile.h"
#import "CDFatFile.h"
#import "CDObjectiveC2Processor64.h"
#import "CDFatArch.h"
#import "CDSearchPathState.h"

void print_usage(void)
{
    fprintf(stderr,
            "class-dump %s\n"
            "Usage: class-dump [options] <mach-o-file>\n"
            "\n"
            "  where options are:\n"
            "        -a             show instance variable offsets\n"
            "        -A             show implementation addresses\n"
            "        --arch <arch>  choose a specific architecture from a universal binary (ppc, ppc64, i386, x86_64)\n"
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
            "        --sdk-root     specify the SDK root path (full path, or 4.1, 4.0, 3.2, 10.6, 10.5, 3.1.3, 3.1.2, 3.1)\n"
            ,
            CLASS_DUMP_VERSION
       );
}

#define CD_OPT_ARCH 1
#define CD_OPT_LIST_ARCHES 2
#define CD_OPT_VERSION 3
#define CD_OPT_SDK_ROOT 4

struct sdk_alias {
    NSString *alias;
    NSString *path;
};

struct sdk_alias sdk_aliases[] = {
    { @"3.0", @"/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS3.0.sdk", },
    { @"3.1", @"/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS3.1.sdk", },
    { @"3.1.2", @"/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS3.1.2.sdk", },
    { @"3.1.3", @"/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS3.1.3.sdk", },
    { @"3.2", @"/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS3.2.sdk", },
    { @"4.0", @"/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS4.0.sdk", },
    { @"4.1", @"/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS4.1.sdk", },
    { @"10.5", @"/Developer/SDKs/MacOSX10.5.sdk", },
    { @"10.6", @"/Developer/SDKs/MacOSX10.6.sdk", },
    { nil, nil, },
};

// Keyed by alias, value is full path.
NSDictionary *sdkAliases(void)
{
    static NSDictionary *aliases = nil;

    if (aliases == nil) {
        NSMutableDictionary *dict;
        struct sdk_alias *ptr = sdk_aliases;

        dict = [[NSMutableDictionary alloc] init];
        while (ptr->alias != nil) {
            [dict setObject:ptr->path forKey:ptr->alias];
            ptr++;
        }
        aliases = [dict copy];
        [dict release];
    }

    return aliases;
}

int main(int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    CDClassDump *classDump;
    CDMultiFileVisitor *multiFileVisitor;
    BOOL shouldFind = NO;
    NSString *searchString = nil;
    BOOL shouldGenerateSeparateHeaders = NO;
    BOOL shouldListArches = NO;
    BOOL shouldPrintVersion = NO;
    CDArch targetArch;
    BOOL hasSpecifiedArch = NO;

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
        { "version", no_argument, NULL, CD_OPT_VERSION },
        { "sdk-root", required_argument, NULL, CD_OPT_SDK_ROOT },
        { NULL, 0, NULL, 0 },
    };

    if (argc == 1) {
        print_usage();
        exit(0);
    }

    classDump = [[[CDClassDump alloc] init] autorelease];
    multiFileVisitor = [[[CDMultiFileVisitor alloc] init] autorelease];
    [multiFileVisitor setClassDump:classDump];

    while ( (ch = getopt_long(argc, argv, "aAC:f:HIo:rRsSt", longopts, NULL)) != -1) {
        switch (ch) {
          case CD_OPT_ARCH: {
              NSString *name;

              name = [NSString stringWithUTF8String:optarg];
              targetArch = CDArchFromName(name);
              if (targetArch.cputype != CPU_TYPE_ANY)
                  hasSpecifiedArch = YES;
              else {
                  fprintf(stderr, "Error: Unknown arch %s\n\n", optarg);
                  errorFlag = YES;
              }
              break;
          }

          case CD_OPT_LIST_ARCHES:
              shouldListArches = YES;
              break;

          case CD_OPT_VERSION:
              shouldPrintVersion = YES;
              break;

          case CD_OPT_SDK_ROOT: {
              NSString *root, *str;
              NSDictionary *aliases = sdkAliases();

              root = [NSString stringWithUTF8String:optarg];
              //NSLog(@"root: %@", root);
              //NSLog(@"aliases: %@", aliases);
              str = [aliases objectForKey:root];
              if (str == nil) {
                  classDump.sdkRoot = root;
              } else {
                  classDump.sdkRoot = str;
              }

              break;
          }

          case 'a':
              [classDump setShouldShowIvarOffsets:YES];
              break;

          case 'A':
              [classDump setShouldShowMethodAddresses:YES];
              break;

          case 'C': {
              NSString *errorMessage;

              if ([classDump setRegex:optarg errorMessage:&errorMessage] == NO) {
                  fprintf(stderr, "class-dump: Error with regex: '%s'\n\n", [errorMessage UTF8String]);
                  errorFlag = YES;
              }
              // Last one wins now.
              break;
          }

          case 'f': {
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
              [multiFileVisitor setOutputPath:[NSString stringWithUTF8String:optarg]];
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

    if (errorFlag) {
        print_usage();
        exit(2);
    }

    if (shouldPrintVersion) {
        printf("class-dump %s compiled %s\n", CLASS_DUMP_VERSION, __DATE__ " " __TIME__);
        exit(0);
    }

    if (optind < argc) {
        NSString *arg, *executablePath;

        arg = [NSString stringWithFileSystemRepresentation:argv[optind]];
        executablePath = [arg executablePathForFilename];
        if (shouldListArches) {
            if (executablePath == nil) {
                printf("none\n");
            } else {
                CDSearchPathState *searchPathState;
                NSData *data;
                id macho;

                searchPathState = [[[CDSearchPathState alloc] init] autorelease];
                searchPathState.executablePath = executablePath;
                data = [[NSData alloc] initWithContentsOfMappedFile:executablePath];
                macho = [CDFile fileWithData:data filename:executablePath searchPathState:searchPathState];
                if (macho == nil) {
                    printf("none\n");
                } else {
                    if ([macho isKindOfClass:[CDMachOFile class]]) {
                        printf("%s\n", [[macho archName] UTF8String]);
                    } else if ([macho isKindOfClass:[CDFatFile class]]) {
                        printf("%s\n", [[[macho archNames] componentsJoinedByString:@" "] UTF8String]);
                    }
                }
                [data release];
            }
        } else {
            CDFile *file;
            NSData *data;

            if (executablePath == nil) {
                fprintf(stderr, "class-dump: Input file (%s) doesn't contain an executable.\n", [arg fileSystemRepresentation]);
                exit(1);
            }

            data = [[NSData alloc] initWithContentsOfMappedFile:executablePath];
            if (data == nil) {
                NSFileManager *defaultManager = [NSFileManager defaultManager];

                if ([defaultManager fileExistsAtPath:executablePath]) {
                    fprintf(stderr, "class-dump: Input file (%s) is not readable (check read rights).\n", [executablePath UTF8String]);
                } else {
                    fprintf(stderr, "class-dump: Input file (%s) does not exist.\n", [executablePath UTF8String]);
                }

                exit(1);
            }

            classDump.searchPathState.executablePath = [executablePath stringByDeletingLastPathComponent];
            file = [CDFile fileWithData:data filename:executablePath searchPathState:classDump.searchPathState];
            if (file == nil) {
                fprintf(stderr, "class-dump: Input file (%s) is neither a Mach-O file nor a fat archive.\n", [executablePath UTF8String]);
                [data release];
                exit(1);
            }
#if 0
            {
                CDFatFile *fat = file;
                NSArray *a1;
                NSUInteger count, index;

                a1 = [fat arches];
                count = [a1 count];
                for (index = 0; index < count; index++)
                    [[[a1 objectAtIndex:index] machOData] writeToFile:[NSString stringWithFormat:@"/tmp/arch-%u", index] atomically:NO];

                exit(99);
            }
#endif
            if (hasSpecifiedArch == NO) {
                if ([file bestMatchForLocalArch:&targetArch] == NO) {
                    fprintf(stderr, "Error: Couldn't get local architecture\n");
                    exit(1);
                }
                //NSLog(@"No arch specified, best match for local arch is: (%08x, %08x)", targetArch.cputype, targetArch.cpusubtype);
            } else {
                //NSLog(@"chosen arch is: (%08x, %08x)", targetArch.cputype, targetArch.cpusubtype);
            }

#ifndef __LP64__
            if (CDArchUses64BitABI(targetArch)) {
                fprintf(stderr, "Error: Can't dump 64-bit files with 32-bit version of class-dump\n");
                exit(1);
            }
#endif

            [classDump setTargetArch:targetArch];
            classDump.searchPathState.executablePath = [executablePath stringByDeletingLastPathComponent];

            if ([classDump loadFile:file]) {
#if 0
                [classDump showHeader];
                [classDump showLoadCommands];
                exit(5);
#endif

                [classDump processObjectiveCData];
                [classDump registerTypes];

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

            [data release];
        }
    }

    [pool release];

    return 0;
}
