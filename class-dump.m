//
//  This file is a part of class-dump v2, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
//
//  You may contact the author by:
//     e-mail:  class-dump at codethecode.com
//

#include <stdio.h>
#include <libc.h>

#import "rcsid.h"
#import <Foundation/Foundation.h>
#import "NSString-Extensions.h"

#import "class-dump.h"
#import "CDClassDump.h"

RCS_ID("$Header: /Volumes/Data/tmp/Tools/class-dump/Attic/class-dump.m,v 1.72 2004/02/04 21:07:14 nygard Exp $");

//======================================================================

char *file_type_names[] =
{
    "MH_<unknown>",
    "MH_OBJECT",
    "MH_EXECUTE",
    "MH_FVMLIB",
    "MH_CORE",
    "MH_PRELOAD",
    "MH_DYLIB",
    "MH_DYLINKER",
    "MH_BUNDLE",
};

char *load_command_names[] =
{
    "LC_<unknown>",
    "LC_SEGMENT",
    "LC_SYMTAB",
    "LC_SYMSEG",
    "LC_THREAD",
    "LC_UNIXTHREAD",
    "LC_LOADFVMLIB",
    "LC_IDFVMLIB",
    "LC_IDENT",
    "LC_FVMFILE",
    "LC_PREPAGE",
    "LC_DYSYMTAB",
    "LC_LOAD_DYLIB",
    "LC_ID_DYLIB",
    "LC_LOAD_DYLINKER",
    "LC_ID_DYLINKER",
    "LC_PREBOUND_DYLIB",
    "LC_ROUTINES",
    "LC_SUB_FRAMEWORK",
};

void print_header(void);

//======================================================================
#if 0
@implementation CDClassDump

- (void)processDylibCommand:(void *)start ptr:(void *)ptr;
{
    struct dylib_command *dc = (struct dylib_command *)ptr;
    NSString *str;
    char *strptr;

    strptr = ptr + dc->dylib.name.offset;
    str = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:strptr length:strlen(strptr)];
    //NSLog(@"strptr: '%s', str: '%@'", strptr, str);
    [self buildUpObjectiveCSegments:str];
}

- (void)processFvmlibCommand:(void *)start ptr:(void *)ptr;
{
    struct fvmlib_command *fc = (struct fvmlib_command *)ptr;
    NSString *str;
    char *strptr;

    strptr = ptr + fc->fvmlib.name.offset;
    str = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:strptr length:strlen(strptr)];
    NSLog(@"strptr: '%s', str: '%@'", strptr, str);
    [self buildUpObjectiveCSegments:str];
}

//======================================================================

- (void)showSingleModule:(CDSectionInfo *)moduleInfo;
{
    struct my_objc_module *m;
    int module_count;
    int l;
    NSString *tmp;
    id en, thing, key;
    NSMutableArray *classList;
    NSArray *newClasses;
    int formatFlags;

    if (moduleInfo == nil)
        return;

    classList = [NSMutableArray array];
    formatFlags = [self methodFormattingFlags];

    tmp = current_filename;
    m = [moduleInfo start];
    module_count = [moduleInfo size] / sizeof(struct my_objc_module);

    {
        MappedFile *currentFile;
        NSString *installName, *filename;
        NSString *key;

        key = [moduleInfo filename];
        currentFile = [mappedFilesByInstallName objectForKey:key];
        installName = [currentFile installName];
        filename = [currentFile filename];
        if (flags.shouldGenerateHeaders == NO) {
            if (filename == nil || [installName isEqual:filename] == YES) {
                printf("\n/*\n * File: %s\n */\n\n", [installName fileSystemRepresentation]);
            } else {
                printf("\n/*\n * File: %s\n * Install name: %s\n */\n\n", [filename fileSystemRepresentation], [installName fileSystemRepresentation]);
            }
        }

        current_filename = key;
    }
    //current_filename = module_info->filename;

    for (l = 0; l < module_count; l++) {
        newClasses = [self handleObjectiveCSymtab:(struct my_objc_symtab *)[self translateAddressToPointer:m->symtab section:CDSECT_SYMBOLS]];
        [classList addObjectsFromArray:newClasses];
        m++;
    }

    if (flags.shouldSort == YES)
        en = [[[protocols allKeys] sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
    else
        en = [[protocols allKeys] objectEnumerator];

    while (key = [en nextObject]) {
        thing = [protocols objectForKey:key];
        if (flags.shouldMatchRegex == NO || [self regexMatchesCString:[[thing sortableName] cString]] == YES)
            [thing showDefinition:formatFlags];
    }

    if (flags.shouldSort == YES && flags.shouldSortClasses == NO)
        en = [[classList sortedArrayUsingSelector:@selector(orderByName:)] objectEnumerator];
    else if (flags.shouldSortClasses == YES)
        en = [[ObjcClass sortedClasses] objectEnumerator];
    else
        en = [classList objectEnumerator];

    while (thing = [en nextObject]) {
        if (flags.shouldMatchRegex == NO || [self regexMatchesCString:[[thing sortableName] cString]] == YES) {
            [thing showDefinition:formatFlags];
        }
    }

    [protocols removeAllObjects];

    current_filename = tmp;
}

@end
#endif
//----------------------------------------------------------------------

void print_usage(void)
{
    fprintf(stderr,
            "class-dump %s\n"
            "Usage: class-dump [options] mach-o-file\n"
            "\n"
            "  where options are:\n"
            "        -a        show instance variable offsets\n"
            "        -A        show implementation addresses\n"
            "        -C regex  only display classes matching regular expression\n"
            "        -H        generate header files in current directory, or directory specified with -o\n"
            "        -I        sort classes, categories, and protocols by inheritance (overrides -s)\n"
            "        -o dir    output directory used for -H\n"
            "        -r        recursively expand frameworks and fixed VM shared libraries\n"
            "        -s        sort classes and categories by name\n"
            "        -S        sort methods by name\n"
            ,
            [CLASS_DUMP_VERSION UTF8String]
       );
}

//======================================================================

extern int optind;
extern char *optarg;

int main(int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    CDClassDump *classDump;

    int ch;
    BOOL errorFlag = NO;

    if (argc == 1) {
        print_usage();
        exit(2);
    }

    classDump = [[[CDClassDump alloc] init] autorelease];
    [classDump setOutputPath:@"/tmp/cd"];

    while ( (ch = getopt(argc, argv, "aAC:HIo:rRsS")) != EOF) {
        switch (ch) {
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
                  NSLog(@"Error with regex: '%@'\n\n", errorMessage);
                  errorFlag = YES;
              }
              // Last one wins now.
          }
              break;

          case 'H':
              [classDump setShouldGenerateSeparateHeaders:YES];
              break;

          case 'I':
              //[classDump setShouldSortByInheritance:YES];
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

    if (optind < argc) {
        NSString *path;

        path = [NSString stringWithFileSystemRepresentation:argv[optind]];
        [classDump processFilename:path];
        [classDump doSomething];
    }

    [pool release];

    return 0;
}
