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
#include <ctype.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <regex.h>
#include <stdio.h>

#include <mach/mach.h>
#include <mach/mach_error.h>

#include <mach-o/loader.h>
#include <mach-o/fat.h>

#import "rcsid.h"
#import <Foundation/Foundation.h>
#import "NSString-Extensions.h"

#import "class-dump.h"

#if 0
#import "CDSectionInfo.h"
#import "ObjcThing.h"
#import "ObjcClass.h"
#import "ObjcCategory.h"
#import "ObjcProtocol.h"
#import "ObjcIvar.h"
#import "ObjcMethod.h"
#import "MappedFile.h"
#endif
#import "CDTypeFormatter.h"
#import "CDTypeParser.h"
#import "CDMachOFile.h"
#import "CDClassDump.h"

RCS_ID("$Header: /Volumes/Data/tmp/Tools/class-dump/Attic/class-dump.m,v 1.58 2004/01/16 23:17:26 nygard Exp $");

//----------------------------------------------------------------------

//int expand_structures_flag = 0; // This is used in datatypes.m
int expand_arg_structures_flag = 0;
#if 0
NSString *current_filename = nil;
#endif
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

- (id)initWithPath:(NSString *)aPath;
{
    if ([super init] == nil)
        return nil;

    mainPath = [aPath retain];
    mappedFiles = [[NSMutableArray alloc] init];
    mappedFilesByInstallName = [[NSMutableDictionary alloc] init];
    sections = [[NSMutableArray alloc] init];

    protocols = [[NSMutableDictionary alloc] init];

    flags.shouldShowIvarOffsets = NO;
    flags.shouldShowMethodAddresses = NO;
    flags.shouldExpandProtocols = NO;
    flags.shouldMatchRegex = NO;
    flags.shouldSort = NO;
    flags.shouldSortClasses = NO;
    flags.shouldGenerateHeaders = NO;
    flags.shouldSwapFat = NO;
    flags.shouldSwapMachO = NO;

    return self;
}

- (void)dealloc;
{
    [mainPath release];
    [mappedFiles release];
    [mappedFilesByInstallName release];
    [sections release];
    [protocols release];

    if (flags.shouldMatchRegex == YES) {
        regfree(&compiledRegex);
    }

    [super dealloc];
}

- (BOOL)shouldShowIvarOffsets;
{
    return flags.shouldShowIvarOffsets;
}

- (void)setShouldShowIvarOffsets:(BOOL)newFlag;
{
    flags.shouldShowIvarOffsets = newFlag;
}

- (BOOL)shouldShowMethodAddresses;
{
    return flags.shouldShowMethodAddresses;
}

- (void)setShouldShowMethodAddresses:(BOOL)newFlag;
{
    flags.shouldShowMethodAddresses = newFlag;
}

- (BOOL)shouldExpandProtocols;
{
    return flags.shouldExpandProtocols;
}

- (void)setShouldExpandProtocols:(BOOL)newFlag;
{
    flags.shouldExpandProtocols = newFlag;
}

- (BOOL)shouldSort;
{
    return flags.shouldSort;
}

- (void)setShouldSort:(BOOL)newFlag;
{
    flags.shouldSort = newFlag;
}

- (BOOL)shouldSortClasses;
{
    return flags.shouldSortClasses;
}

- (void)setShouldSortClasses:(BOOL)newFlag;
{
    flags.shouldSortClasses = newFlag;
}

- (BOOL)shouldGenerateHeaders;
{
    return flags.shouldGenerateHeaders;
}

- (void)setShouldGenerateHeaders:(BOOL)newFlag;
{
    flags.shouldGenerateHeaders = newFlag;
}

- (BOOL)shouldMatchRegex;
{
    return flags.shouldMatchRegex;
}

- (void)setShouldMatchRegex:(BOOL)newFlag;
{
    flags.shouldMatchRegex = newFlag;
}

- (BOOL)setRegex:(char *)regexCString errorMessage:(NSString **)errorMessagePointer;
{
    int result;

    if (flags.shouldMatchRegex == YES) {
        regfree(&compiledRegex);
    }

    result = regcomp(&compiledRegex, regexCString, REG_EXTENDED);
    if (result != 0) {
        char regex_error_buffer[256];

        if (regerror(result, &compiledRegex, regex_error_buffer, 256) > 0) {
            if (errorMessagePointer != NULL) {
                *errorMessagePointer = [NSString stringWithCString:regex_error_buffer];
                NSLog(@"Error with regex: '%@'", *errorMessagePointer);
            }
        } else {
            if (errorMessagePointer != NULL)
                *errorMessagePointer = nil;
        }

        return NO;
    }

    [self setShouldMatchRegex:YES];

    return YES;
}

- (BOOL)regexMatchesCString:(const char *)str;
{
    int result;

    if (flags.shouldMatchRegex == NO)
        return YES;

    result = regexec(&compiledRegex, str, 0, NULL, 0);

    return (result == 0) ? YES : NO;
}

- (NSArray *)sections;
{
    return sections;
}

- (void)addSectionInfo:(CDSectionInfo *)aSectionInfo;
{
    [sections addObject:aSectionInfo];
}

//======================================================================

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

//----------------------------------------------------------------------

- (NSArray *)handleObjectiveCMethods:(struct my_objc_methods *)methods methodType:(char)ch;
{
    struct my_objc_method *method = (struct my_objc_method *)(methods + 1);
    NSMutableArray *methodArray = [NSMutableArray array];
    ObjcMethod *objcMethod;
    int l;

    if (methods == NULL)
        return nil;

    for (l = 0; l < methods->method_count; l++)
    {
        // Sometimes the name, types, and implementation are all zero.  However, the
        // implementation may legitimately be zero (most often the first method of an object file),
        // so we check the name instead.

        if (method->name != 0)
        {
            objcMethod = [[[ObjcMethod alloc] initWithMethodName:[self nsstringAt:method->name section:CDSECT_METH_VAR_NAMES]
                                              type:[self nsstringAt:method->types section:CDSECT_METH_VAR_TYPES]
                                              address:method->imp] autorelease];
            [methodArray addObject:objcMethod];
        }
        method++;
    }

    return methodArray;
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

    // begin wolf
    id en2, thing2;
    NSMutableDictionary *categoryByName = [NSMutableDictionary dictionaryWithCapacity:5];
    // end wolf

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

    //begin wolf
    if (flags.shouldGenerateHeaders == YES) {
        printf("Should generate headers...\n");
#if 1
        en = [[protocols allKeys] objectEnumerator];
        while (key = [en nextObject]) {
            int old_stdout = dup(1);

            thing = [protocols objectForKey:key];
            freopen([[NSString stringWithFormat:@"%@.h", [thing protocolName]] cString], "w", stdout);
            [thing showDefinition:formatFlags];
            fclose(stdout);
            fdopen(old_stdout, "w");
        }

        en = [classList objectEnumerator];
        while (thing = [en nextObject]) {
            if ([thing isKindOfClass:[ObjcCategory class]] ) {
                NSMutableArray *categoryArray = [categoryByName objectForKey:[thing categoryName]];

                if (categoryArray != nil) {
                    [categoryArray addObject:thing];
                } else {
                    [categoryByName setObject:[NSMutableArray arrayWithObject:thing] forKey:[thing categoryName]];
                }
            } else {
                int old_stdout = dup(1);

                freopen([[NSString stringWithFormat:@"%@.h", [thing className]] cString], "w", stdout);
                [thing showDefinition:formatFlags];
                fclose(stdout);
                fdopen(old_stdout, "w");
            }
        }

        en = [[categoryByName allKeys] objectEnumerator];
        while (key = [en nextObject]) {
            int old_stdout = dup(1);

            freopen([[NSString stringWithFormat:@"%@.h", key] cString], "w", stdout);

            print_header();
            printf("\n");
            thing = [categoryByName objectForKey:key];
            en2 = [thing objectEnumerator];
            while (thing2 = [en2 nextObject]) {
                [thing2 showDefinition:formatFlags];
            }

            fclose(stdout);
            fdopen(old_stdout, "w");
        }
#endif
        // TODO: nothing prints to stdout after this.
        printf("Testing... 1.. 2.. 3..\n");
    }
    //end wolf

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

- (int)methodFormattingFlags;
{
    int formatFlags = 0;

    if (flags.shouldSort == YES)
        formatFlags |= F_SORT_METHODS;

    if (flags.shouldShowIvarOffsets == YES)
        formatFlags |= F_SHOW_IVAR_OFFSET;

    if (flags.shouldShowMethodAddresses == YES)
        formatFlags |= F_SHOW_METHOD_ADDRESS;

    if (flags.shouldGenerateHeaders == YES)
        formatFlags |= F_SHOW_IMPORT;

    return formatFlags;
}

@end
#endif
//----------------------------------------------------------------------

void print_usage(void)
{
    fprintf(stderr,
            "class-dump %s\n"
            "Usage: class-dump [-a] [-A] [-e] [-R] [-C regex] [-r] [-S] executable-file\n"
            "        -a  show instance variable offsets\n"
            "        -A  show implementation addresses\n"
            "        -e  expand structure (and union) definition in ivars whenever possible\n"
            "        -E  expand structure (and union) definition in method arguments whenever possible\n"
            "        -I  sort by inheritance (overrides -S)\n"
            "        -R  recursively expand @protocol <>\n"
            "        -C  only display classes matching regular expression\n"
            "        -r  recursively expand frameworks and fixed VM shared libraries\n"
            "        -S  sort protocols, classes, and methods\n"
            "        -H  generate header files in current directory\n",
            [CLASS_DUMP_VERSION UTF8String]
       );
}

//----------------------------------------------------------------------

void testVariableTypes(NSString *path)
{
    CDTypeFormatter *ivarTypeFormatter;
    NSMutableString *resultString;
    NSString *contents;
    NSArray *lines, *fields;
    int count, index;

    ivarTypeFormatter = [[CDTypeFormatter alloc] init];
    [ivarTypeFormatter setShouldExpand:NO];
    [ivarTypeFormatter setShouldAutoExpand:YES];
    [ivarTypeFormatter setBaseLevel:1];
    //[ivarTypeFormatter setDelegate:self];

    resultString = [NSMutableString string];
    [resultString appendFormat:@"Testing %@\n", path];

    contents = [NSString stringWithContentsOfFile:path];
    lines = [contents componentsSeparatedByString:@"\n"];
    count = [lines count];

    for (index = 0; index < count; index++) {
        NSString *line;
        NSString *type, *name;

        line = [lines objectAtIndex:index];
        fields = [line componentsSeparatedByString:@"\t"];
        if ([line length] > 0) {
            int fieldCount, level;
            NSString *formattedString;

            fieldCount = [fields count];
            type = [fields objectAtIndex:0];
            if (fieldCount > 1)
                name = [fields objectAtIndex:1];
            else
                name = @"var";

            if (fieldCount > 2)
                level = [[fields objectAtIndex:2] intValue];
            else
                level = 0;

            [resultString appendFormat:@"type: '%@'\n", type];
            [resultString appendFormat:@"name: '%@'\n", name];
            [resultString appendFormat:@"level: %d\n", level];
            formattedString = [ivarTypeFormatter formatVariable:name type:type];
            if (formattedString != nil) {
                [resultString appendString:formattedString];
                [resultString appendString:@"\n"];
            } else {
                [resultString appendString:@"Parse failed.\n"];
            }
            [resultString appendString:@"\n"];
        }
    }

    [resultString appendString:@"Done.\n"];

    {
        NSData *data;

        data = [resultString dataUsingEncoding:NSUTF8StringEncoding];
        [(NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput] writeData:data];
    }

}
#if 0
void testMethodTypes(NSString *path)
{
    NSString *contents;
    NSArray *lines, *fields;
    int count, index;

    NSLog(@"Testing %@", path);
    contents = [NSString stringWithContentsOfFile:path];

    lines = [contents componentsSeparatedByString:@"\n"];
    count = [lines count];
    for (index = 0; index < count; index++) {
        NSString *line;
        NSString *type, *name;

        line = [lines objectAtIndex:index];
        if ([line hasPrefix:@"\tClass "] == YES) {
            NSLog(@"Class %@", [line substringFromIndex:7]);
            continue;
        }

        fields = [line componentsSeparatedByString:@"\t"];
        if ([fields count] >= 2) {
            NSString *result;

            name = [fields objectAtIndex:0];
            type = [fields objectAtIndex:1];
            NSLog(@"%@\t%@", name, type);
            result = [CDTypeFormatter formatMethodName:name type:type];
            if (result != nil) {
                //NSLog(@"Parsed okay");
                NSLog(@"result: %@", result);
            } else {
                NSLog(@"Parse failed");
            }
            //printf("\t%s\t%s", type, name);
            //printf("\n");
        }
    }

    NSLog(@"Done.");
}
#endif

//======================================================================

int main(int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    int c;
    extern int optind;
    extern char *optarg;
    int error_flag = 0;
    BOOL shouldShowIvarOffsets = NO;
    BOOL shouldShowMethodAddresses = NO;
    BOOL shouldExpandProtocols = NO;
    //BOOL shouldMatchRegex = NO;
    BOOL shouldExpandFrameworks = NO;
    BOOL shouldSort = NO;
    BOOL shouldSortClasses = NO;
    BOOL shouldGenerateHeaders = NO;
    BOOL shouldTestVariableTypes = NO;
    BOOL shouldTestMethodTypes = NO;
    char *regexCString = NULL;

    if (argc == 1) {
        print_usage();
        exit(2);
    }

    while ( (c = getopt(argc, argv, "aAeIRC:rSHtT")) != EOF) {
        switch (c) {
          case 'a':
              shouldShowIvarOffsets = YES;
              break;

          case 'A':
              shouldShowMethodAddresses = YES;
              break;

          case 'e':
              //expand_structures_flag = 1;
              break;

          case 'E':
              expand_arg_structures_flag = 1;
              break;

          case 'R':
              shouldExpandProtocols = YES;
              break;

          case 'C':
              if (regexCString != NULL) {
                  printf("Error: sorry, only one -C allowed\n");
                  error_flag++;
              } else {
                  regexCString = optarg;
              }
              break;

          case 'r':
              shouldExpandFrameworks = YES;
              break;

          case 'S':
              shouldSort = YES;
              break;

          case 'I':
              shouldSortClasses = YES;
              break;

          case 'H':
              shouldGenerateHeaders = YES;
              break;

          case 't':
              shouldTestVariableTypes = YES;
              break;

          case 'T':
              shouldTestMethodTypes = YES;
              break;

          case '?':
          default:
              error_flag++;
              break;
        }
    }

    if (error_flag > 0) {
        print_usage();
        exit(2);
    }

    if (shouldTestVariableTypes == YES) {
        int index;

        for (index = optind; index < argc; index++) {
            char *str;
            NSString *path;

            str = argv[index];
            path = [[NSString alloc] initWithBytes:str length:strlen(str) encoding:NSASCIIStringEncoding];
            testVariableTypes(path);
        }

        exit(0);
    }

    if (optind < argc) {
        char *str;
        NSString *path, *adjustedPath;
        CDClassDump2 *classDump;

        str = argv[optind];
        path = [NSString stringWithFileSystemRepresentation:str];
        NSLog(@"path: '%@'", path);
        adjustedPath = [CDClassDump2 adjustUserSuppliedPath:path];
        NSLog(@"adjustedPath: '%@'", adjustedPath);

        classDump = [[CDClassDump2 alloc] init];
        [classDump setShouldProcessRecursively:shouldExpandFrameworks];
        [classDump processFilename:adjustedPath];
        [classDump doSomething];
        [classDump release];

        exit(99);

#if 0
        char *str;
        NSString *targetPath, *adjustedPath;
        CDClassDump *classDump;
        NSString *regexErrorMessage;

        //targetPath = [[NSString alloc] initWithCString:argv[optind]];
        str = argv[optind];
        targetPath = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:str length:strlen(str)];
        NSLog(@"targetPath: '%@'", targetPath);
        adjustedPath = [MappedFile adjustUserSuppliedPath:targetPath];
        NSLog(@"adjusted user supplied path: '%@'", adjustedPath);

        classDump = [[CDClassDump alloc] initWithPath:adjustedPath];
        [classDump setShouldShowIvarOffsets:shouldShowIvarOffsets];
        [classDump setShouldShowMethodAddresses:shouldShowMethodAddresses];
        [classDump setShouldExpandProtocols:shouldExpandProtocols];
        [classDump setShouldSort:shouldSort];
        [classDump setShouldSortClasses:shouldSortClasses];
        [classDump setShouldGenerateHeaders:shouldGenerateHeaders];
        if (regexCString != NULL) {
            if ([classDump setRegex:regexCString errorMessage:&regexErrorMessage] == NO) {
                printf("Error with regex: %s\n", [regexErrorMessage cString]);
                [classDump release];
                exit(1);
            }
        }

        [classDump buildUpObjectiveCSegments:adjustedPath];
        [classDump sortObjectiveCSegments];

        if ([classDump shouldGenerateHeaders] == NO)
            print_header();

        print_unknown_struct_typedef();

        //[classDump debugSectionOverlap];

        if ([[classDump sections] count] > 0) {
            if (shouldExpandFrameworks == NO) {
                [classDump showSingleModule:[classDump objectiveCSectionWithName:CDSECT_MODULE_INFO filename:adjustedPath]];
            } else {
                [classDump showAllModules];
            }
        }

        [classDump release];
#endif
    }

    [pool release];

    return 0;
}
