//
// $Id: class-dump.m,v 1.51 2004/01/05 21:01:25 nygard Exp $
//

//
//  This file is a part of class-dump v2, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997, 1998, 1999, 2000, 2001, 2002  Steve Nygard
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

#import <Foundation/Foundation.h>
#import "NSString-Extensions.h"

#include "datatypes.h"
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

//----------------------------------------------------------------------

#define CLASS_DUMP_VERSION "3.0 alpha"

//int expand_structures_flag = 0; // This is used in datatypes.m
int expand_arg_structures_flag = 0;
#if 0
NSString *current_filename = nil;

//----------------------------------------------------------------------

static NSString *CDSECT_CLASS =          @"__class";
static NSString *CDSECT_SYMBOLS =        @"__symbols";
#define SECT_CSTRING                      "__cstring"  /* In SEG_TEXT segments */
static NSString *CDSECT_CSTRING =        @"__cstring";  /* In SEG_TEXT segments */
static NSString *CDSECT_PROTOCOL =       @"__protocol";
static NSString *CDSECT_CATEGORY =       @"__category";
static NSString *CDSECT_CLS_METH =       @"__cls_meth";
static NSString *CDSECT_INST_METH =      @"__inst_meth";
static NSString *CDSECT_META_CLASS =     @"__meta_class";
static NSString *CDSECT_CLASS_NAMES =    @"__class_names";
static NSString *CDSECT_MODULE_INFO =    @"__module_info";
static NSString *CDSECT_CAT_CLS_METH =   @"__cat_cls_meth";
static NSString *CDSECT_INSTANCE_VARS =  @"__instance_vars";
static NSString *CDSECT_CAT_INST_METH =  @"__cat_inst_meth";
static NSString *CDSECT_METH_VAR_TYPES = @"__meth_var_types";
static NSString *CDSECT_METH_VAR_NAMES = @"__meth_var_names";
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

- (void)processFile:(MappedFile *)aMappedFile;
{
    void *ptr;
    struct mach_header *mh;
    struct fat_header *fh;
    struct fat_arch *fa;
    int l;
    int result = 1;

    ptr = (void *)[aMappedFile data];
    mh = (struct mach_header *)ptr;
    fh = (struct fat_header *)ptr;
    fa = (struct fat_arch *)(fh + 1);

    if (mh->magic == FAT_CIGAM) {
        // Fat file... Other endian.

        flags.shouldSwapFat = YES;
        for (l = 0; l < NXSwapLong(fh->nfat_arch); l++) {
#ifdef VERBOSE
            printf("archs: %ld\n", NXSwapLong(fh->nfat_arch));
            printf("offset: %lx\n", NXSwapLong(fa->offset));
            printf("arch: %08lx\n", NXSwapLong(fa->cputype));
#endif
            result = [self processMachO:(ptr + NXSwapLong(fa->offset)) filename:[aMappedFile installName]];
            if (result == 0)
                break;
            fa++;
        }
    } else if (mh->magic == FAT_MAGIC) {
        // Fat file... This endian.

        for (l = 0; l < fh->nfat_arch; l++) {
#ifdef VERBOSE
            printf("archs: %ld\n", fh->nfat_arch);
            printf("offset: %lx\n", fa->offset);
            printf("arch: %08x\n", fa->cputype);
#endif
            result = [self processMachO:ptr + fa->offset filename:[aMappedFile installName]];
            if (result == 0)
                break;
            fa++;
        }
    } else {
        result = [self processMachO:ptr filename:[aMappedFile installName]];
    }

    switch (result) {
      case 0:
          break;

      case 1:
          printf("Error: File did not contain an executable with our endian.\n");
          break;

      default:
          printf("Error: processing Mach-O file.\n");
    }
}

//----------------------------------------------------------------------

// Returns 0 if this was our endian, 1 if it was not, 2 otherwise.

- (int)processMachO:(void *)ptr filename:(NSString *)filename;
{
    struct mach_header *mh = (struct mach_header *)ptr;
    int l;
    void *start = ptr;

    if (mh->magic == MH_CIGAM) {
        flags.shouldSwapMachO = YES;
        return 1;
    } else if (mh->magic != MH_MAGIC) {
        printf("This is not a Mach-O file.\n");
        return 2;
    }

    ptr += sizeof(struct mach_header);

    for (l = 0; l < mh->ncmds; l++) {
        ptr += [self processLoadCommand:start ptr:ptr filename:filename];
    }

    return 0;
}

//----------------------------------------------------------------------

- (unsigned long)processLoadCommand:(void *)start ptr:(void *)ptr filename:(NSString *)filename;
{
    struct load_command *lc = (struct load_command *)ptr;

#ifdef VERBOSE
    if (lc->cmd <= LC_SUB_FRAMEWORK) {
        printf("%s\n", load_command_names[ lc->cmd ]);
    } else {
        printf("%08lx\n", lc->cmd);
    }
#endif

    if (lc->cmd == LC_SEGMENT) {
        [self processSegmentCommand:start ptr:ptr filename:filename];
    } else if (lc->cmd == LC_LOAD_DYLIB) {
        [self processDylibCommand:start ptr:ptr];
    } else if (lc->cmd == LC_LOADFVMLIB) {
        [self processFvmlibCommand:start ptr:ptr];
    }

    return lc->cmdsize;
}

//----------------------------------------------------------------------

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

//----------------------------------------------------------------------

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

- (void)processSegmentCommand:(void *)start ptr:(void *)ptr filename:(NSString *)filename;
{
    struct segment_command *sc = (struct segment_command *)ptr;
    char name[17];

    strncpy(name, sc->segname, 16);
    name[16] = 0;

    if (!strcmp(name, SEG_OBJC)
        || !strcmp(name, SEG_TEXT) /* for MacOS X __cstring sections */
        ||  !strcmp(name, "") /* for .o files. */
        )
    {
        [self processObjectiveCSegment:start ptr:ptr filename:filename];
    }
}

//----------------------------------------------------------------------

- (void)processObjectiveCSegment:(void *)start ptr:(void *)ptr filename:(NSString *)filename;
{
    struct segment_command *sc = (struct segment_command *)ptr;
    struct section *section = (struct section *)(sc + 1);
    int l;

    //NSLog(@"process_objc_segment, %d: %@", section_count, filename);
    for (l = 0; l < sc->nsects; l++) {
        if (!strcmp(section->segname, SEG_OBJC) || (!strcmp(section->segname, SEG_TEXT) && !strcmp(section->sectname, SECT_CSTRING))) {
            NSString *name;
            CDSectionInfo *sectionInfo;

            name = [[NSString alloc] initWithCString:section->sectname maximumLength:16];
            sectionInfo = [[CDSectionInfo alloc] initWithFilename:filename
                                                 name:name
                                                 section:section
                                                 start:start + section->offset
                                                 vmaddr:section->addr
                                                 size:section->size];
            [name release];

            [self addSectionInfo:sectionInfo];
            [sectionInfo release];
        }

        section++;
    }
}

//----------------------------------------------------------------------

- (NSArray *)handleObjectiveCSymtab:(struct my_objc_symtab *)symtab;
{
    NSMutableArray *classList = [NSMutableArray array];
    ObjcThing *objcThing;
    long *class_pointer;
    int l;

    if (symtab == NULL) {
        printf("// NULL symtab...\n");
        return nil;
    }

    class_pointer = &symtab->class_pointer;

    for (l = 0; l < symtab->cls_def_count; l++) {
        objcThing = [self handleObjectiveCClass:[self translateAddressToPointer:*class_pointer section:CDSECT_CLASS]];
        if (objcThing != nil)
            [classList addObject:objcThing];

        class_pointer++;
    }

    for (l = 0; l < symtab->cat_def_count; l++) {
        objcThing = [self handleObjectiveCCategory:[self translateAddressToPointer:*class_pointer section:CDSECT_CATEGORY]];
        if (objcThing != nil)
            [classList addObject:objcThing];

        class_pointer++;
    }

    return classList;
}

//----------------------------------------------------------------------

- (ObjcClass *)handleObjectiveCClass:(struct my_objc_class *)ocl;
{
    ObjcClass *objcClass;
    NSArray *tmp;

    if (ocl == NULL)
        return nil;

    tmp = [self handleObjectiveCProtocols:(struct my_objc_protocol_list *)[self translateAddressToPointer:ocl->protocols section:CDSECT_CAT_CLS_METH]
                expandProtocols:YES];

    if ([self stringAt:ocl->super_class section:CDSECT_CLASS_NAMES] == NULL)
    {
        objcClass = [[[ObjcClass alloc] initWithClassName:[self nsstringAt:ocl->name section:CDSECT_CLASS_NAMES] superClassName:nil] autorelease];
    }
    else
    {
        objcClass = [[[ObjcClass alloc] initWithClassName:[self nsstringAt:ocl->name section:CDSECT_CLASS_NAMES]
                                        superClassName:[self nsstringAt:ocl->super_class section:CDSECT_CLASS_NAMES]] autorelease];
    }

    [objcClass addProtocolNames:tmp];

    tmp = [self handleObjectiveCIvars:(struct my_objc_ivars *)[self translateAddressToPointer:ocl->ivars section:CDSECT_INSTANCE_VARS]];
    [objcClass addIvars:tmp];

    tmp = [self handleObjectiveCMetaClass:(struct my_objc_class *)[self translateAddressToPointer:ocl->isa section:CDSECT_META_CLASS]];
    [objcClass addClassMethods:tmp];

    tmp = [self handleObjectiveCMethods:(struct my_objc_methods *)[self translateAddressToPointer:ocl->methods section:CDSECT_INST_METH] methodType:'-'];
    [objcClass addInstanceMethods:tmp];

    return objcClass;
}

//----------------------------------------------------------------------

- (ObjcCategory *)handleObjectiveCCategory:(struct my_objc_category *)ocat;
{
    ObjcCategory *objcCategory;
    NSArray *tmp;

    if (ocat == NULL)
        return nil;

    objcCategory = [[[ObjcCategory alloc] initWithClassName:[self nsstringAt:ocat->class_name section:CDSECT_CLASS_NAMES]
                                          categoryName:[self nsstringAt:ocat->category_name section:CDSECT_CLASS_NAMES]] autorelease];

    tmp = [self handleObjectiveCMethods:(struct my_objc_methods *)[self translateAddressToPointer:ocat->class_methods section:CDSECT_CAT_CLS_METH] methodType:'+'];
    [objcCategory addClassMethods:tmp];

    tmp = [self handleObjectiveCMethods:(struct my_objc_methods *)[self translateAddressToPointer:ocat->methods section:CDSECT_CAT_INST_METH] methodType:'-'];
    [objcCategory addInstanceMethods:tmp];

    return objcCategory;
}

//----------------------------------------------------------------------

// Return list of protocol names.
- (NSArray *)handleObjectiveCProtocols:(struct my_objc_protocol_list *)plist expandProtocols:(BOOL)expandProtocols;
{
    NSMutableArray *protocolArray = [NSMutableArray array];
    ObjcProtocol *objcProtocol;
    struct my_objc_protocol *prot;
    struct my_objc_prot_inst_meth_list *mlist;
    struct my_objc_prot_inst_meth *meth;
    int l, p;
    long *ptr;
    NSArray *parentProtocols;

    if (plist == NULL)
        return nil;

    ptr = &plist->list;

    for (p = 0; p < plist->count; p++)
    {
        prot = [self translateAddressToPointer:*ptr section:CDSECT_PROTOCOL];

        objcProtocol = [[[ObjcProtocol alloc] initWithProtocolName:[self nsstringAt:prot->protocol_name section:CDSECT_CLASS_NAMES]] autorelease];
        [protocolArray addObject:[objcProtocol protocolName]];

        parentProtocols = [self handleObjectiveCProtocols:[self translateAddressToPointer:prot->protocol_list section:CDSECT_CAT_CLS_METH]
                                expandProtocols:flags.shouldExpandProtocols]; // TODO: Hmm, is this correct? Shouldn't it be expandProtocols?
        [objcProtocol addProtocolNames:parentProtocols];

        mlist = [self translateAddressToPointer:prot->instance_methods section:CDSECT_CAT_INST_METH];
        if (mlist != NULL)
        {
            meth = (struct my_objc_prot_inst_meth *)&mlist->methods;

            for (l = 0; l < mlist->count; l++)
            {
                [objcProtocol addProtocolMethod:[[[ObjcMethod alloc] initWithMethodName:[self nsstringAt:meth->name section:CDSECT_METH_VAR_NAMES]
                                                                     type:[self nsstringAt:meth->types section:CDSECT_METH_VAR_TYPES]] autorelease]];
                meth++;
            }
        }

        if (expandProtocols == YES && [protocols objectForKey:[objcProtocol protocolName]] == nil)
        {
            [protocols setObject:objcProtocol forKey:[objcProtocol protocolName]];
            objcProtocol = nil;
        }

        ptr++;
    }

    return protocolArray;
}

//----------------------------------------------------------------------

- (NSArray *)handleObjectiveCMetaClass:(struct my_objc_class *)ocl;
{
    if (ocl == NULL)
        return nil;

    return [self handleObjectiveCMethods:(struct my_objc_methods *)[self translateAddressToPointer:ocl->methods section:CDSECT_CLS_METH] methodType:'+'];
}

//----------------------------------------------------------------------

- (NSArray *)handleObjectiveCIvars:(struct my_objc_ivars *)ivars;
{
    struct my_objc_ivar *ivar = (struct my_objc_ivar *)(ivars + 1);
    NSMutableArray *ivarArray = [NSMutableArray array];
    ObjcIvar *objcIvar;
    int l;

    if (ivars == NULL)
        return nil;

    for (l = 0; l < ivars->ivar_count; l++)
    {
        objcIvar = [[[ObjcIvar alloc] initWithName:[self nsstringAt:ivar->name section:CDSECT_METH_VAR_NAMES]
                                      type:[self nsstringAt:ivar->type section:CDSECT_METH_VAR_TYPES]
                                      offset:ivar->offset] autorelease];
        [ivarArray addObject:objcIvar];

        ivar++;
    }

    return ivarArray;
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

//----------------------------------------------------------------------

- (void)showAllModules;
{
    int count, index;
    CDSectionInfo *sectionInfo;

    count = [sections count];
    for (index = count - 1; index >= 0; index--) {
        sectionInfo = [sections objectAtIndex:index];
        if ([[sectionInfo name] isEqual:CDSECT_MODULE_INFO] == YES)
            [self showSingleModule:sectionInfo];
    }
}

//----------------------------------------------------------------------

- (void)buildUpObjectiveCSegments:(NSString *)filename;
{
    MappedFile *mappedFile;
    int count, index;

    // Only process each file once.

    //NSLog(@"%s", _cmd);

    //NSLog(@"filename: '%@'", filename);
    //NSLog(@"mappedFiles: %@", [mappedFiles description]);
    count = [mappedFiles count];
    for (index = 0; index < count; index++) {
        if ([filename isEqual:[[mappedFiles objectAtIndex:index] installName]] == YES) {
            //NSLog(@"Already have file %@, skipping.", filename);
            return;
        }
    }

    mappedFile = [[MappedFile alloc] initWithFilename:filename];
    if (mappedFile != nil) {
        [mappedFiles addObject:mappedFile];
        [mappedFilesByInstallName setObject:mappedFile forKey:[mappedFile installName]];

        [self processFile:mappedFile]; // Use installName instead of passing filename
        [mappedFile release];
    }
}

//
// Utility Methods
//

// Find the Objective-C segment for the given filename noted in our
// list.

- (CDSectionInfo *)objectiveCSectionWithName:(NSString *)name filename:(NSString *)filename;
{
    int count, index;
    CDSectionInfo *sectionInfo;

    count = [sections count];
    for (index = 0; index < count; index++) {
        sectionInfo = [sections objectAtIndex:index];
        if ([name isEqual:[sectionInfo name]] == YES && [filename isEqual:[sectionInfo filename]] == YES)
            return sectionInfo;
    }

    return nil;
}

//----------------------------------------------------------------------

- (void)sortObjectiveCSegments;
{
    [sections sortUsingSelector:@selector(ascendingCompareByAddress:)];
}

- (void)debugSectionOverlap;
{
    int count, index;
    CDSectionInfo *previousSection, *currentSection;
    //NSArray *sortedSections;

    NSLog(@"sections:\n%@", [sections description]);

    //sortedSections = [sections sortedArrayUsingSelector:@selector(ascendingCompareByAddress:)];
    //NSLog(@"sortedSections:\n%@", [sortedSections description]);

    previousSection = nil;
    count = [sections count];
    for (index = 0; index < count; index++) {
        currentSection = [sections objectAtIndex:index];

        if (previousSection != nil) {
            if ([currentSection vmaddr] < [previousSection endAddress])
                NSLog(@"Looks like these two sections overlap:\n%@\n%@", previousSection, currentSection);
        }

        previousSection = currentSection;
    }
}

//----------------------------------------------------------------------

//
// Take a long from the Mach-O file (which is really a pointer when
// the section is loaded at the proper location) and translate it into
// a pointer to where we have the file mapped.
//

- (void *)translateAddressToPointer:(long)addr section:(NSString *)section;
{
    return [self translateAddressToPointerComplain:addr section:section complain:YES];
}

- (void *)translateAddressToPointerComplain:(long)addr section:(NSString *)section complain:(BOOL)shouldComplain;
{
    int matchCount;
    int count, index;
    CDSectionInfo *sectionInfo;

    matchCount = 0;
    count = [sections count];

    // TODO (2003-02-20): Save the last matched section.
    for (index = 0; index < count; index++) {
        sectionInfo = [sections objectAtIndex:index];
        if ([sectionInfo containsAddress:addr] == YES && [[sectionInfo name] isEqual:section] == YES)
            matchCount++;
    }

    if (matchCount > 1) {
        // TODO (2003-02-20): Do testing to check for dupes.
        //NSLog(@"Dupes (%d).", matchCount);
        // If there are still duplicates, we choose the one for the current file.
        for (index = 0; index < count; index++) {
            sectionInfo = [sections objectAtIndex:index];
            if ([sectionInfo containsAddress:addr] == YES
                && [[sectionInfo name] isEqual:section] == YES
                && [[sectionInfo filename] isEqual:current_filename] == YES)
            {
                return [sectionInfo translateAddress:addr];
            }
        }
    } else {
        for (index = 0; index < count; index++) {
            sectionInfo = [sections objectAtIndex:index];
            if ([sectionInfo containsAddress:addr] == YES && [[sectionInfo name] isEqual:section] == YES)
                return [sectionInfo translateAddress:addr];
        }
    }

    if (addr != 0 && shouldComplain == YES)
        NSLog(@"address (0x%08lx) not in '%@' section of OBJC segment!", addr, section);

    return NULL;
}

//----------------------------------------------------------------------

- (char *)stringAt:(long)addr section:(NSString *)section;
{
    char *ptr;

    /* String addresses are located in a different section in MacOS X binaries.
       Look there first, and only print error message if not found in either
       the old or new style section.  MacOS X still supports older Mac OS X
       Server binaries, so we do need to look in both places.
     */
    ptr = (char *)[self translateAddressToPointerComplain:addr section:CDSECT_CSTRING complain:NO];
    if (ptr == NULL)
	ptr = (char *)[self translateAddressToPointerComplain:addr section:section complain:YES];

    return ptr;
}

//----------------------------------------------------------------------

- (NSString *)nsstringAt:(long)addr section:(NSString *)section;
{
    char *str;

    str = [self stringAt:addr section:section];

    return (str == NULL) ? (NSString *)@"" : [NSString stringWithCString:str];
}

//----------------------------------------------------------------------

- (CDSectionInfo *)sectionOfAddress:(long)addr;
{
    int count, index;
    CDSectionInfo *sectionInfo;

    count = [sections count];
    for (index = 0; index < count; index++) {
        sectionInfo = [sections objectAtIndex:index];
        if ([sectionInfo containsAddress:addr] == YES)
            return sectionInfo;
    }

    return NULL;
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
            CLASS_DUMP_VERSION
       );
}

//----------------------------------------------------------------------

void print_header(void)
{
    printf(
        "/*\n"
        " *     Generated by class-dump (version %s).\n"
        " *\n"
        " *     class-dump is Copyright (C) 1997, 1999-2003 by Steve Nygard.\n"
        " */\n", CLASS_DUMP_VERSION
       );
}

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
        NSString *path;
        CDClassDump2 *classDump;

        str = argv[optind];
        path = [[NSString alloc] initWithBytes:str length:strlen(str) encoding:NSASCIIStringEncoding];

        classDump = [[CDClassDump2 alloc] init];
        //[classDump setShouldProcessRecursively:YES];
        [classDump processFilename:path];
        [classDump doSomething];
        [classDump release];

        [path release];
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
