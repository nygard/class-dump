//
// $Id: class-dump.m,v 1.15 2002/12/19 05:21:11 nygard Exp $
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
//     e-mail:  nygard@omnigroup.com
//

#include <stdio.h>
#include <libc.h>
#include <ctype.h>

#include <sys/types.h>
#include <sys/stat.h>

#include <mach/mach.h>
#include <mach/mach_error.h>

#include <mach-o/loader.h>
#include <mach-o/fat.h>

#if NS_TARGET_MAJOR >= 4 || defined(__APPLE__)
#import <Foundation/Foundation.h>
#define USE_FILE_SYSTEM_REPRESENTATION
#else
#import <foundation/NSString.h>
#import <foundation/NSArray.h>
#import <foundation/NSDictionary.h>
#import <foundation/NSAutoreleasePool.h>
#import <foundation/NSUtilities.h>
#endif

#include "datatypes.h"
#include "class-dump.h"

#include "my_regex.h"

#import "ObjcThing.h"
#import "ObjcClass.h"
#import "ObjcCategory.h"
#import "ObjcProtocol.h"
#import "ObjcIvar.h"
#import "ObjcMethod.h"
#import "MappedFile.h"

#ifndef LC_SUB_FRAMEWORK
#define LC_SUB_FRAMEWORK 0x12
#endif

#ifndef LC_LOAD_DYLIB
#define LC_LOAD_DYLIB 0x0c

struct dylib {
    union lc_str  name;
    unsigned long timestamp;
    unsigned long current_version;
    unsigned long compatibility_version;
};

struct dylib_command {
    unsigned long	cmd;
    unsigned long	cmdsize;
    struct dylib	dylib;
};
#endif

//----------------------------------------------------------------------

#define CLASS_DUMP_VERSION "2.1.6 alpha"

int expand_structures_flag = 0;
int char_star_flag = 0;

BOOL show_ivar_offsets_flag = NO;
BOOL show_method_addresses_flag = NO;
BOOL expand_protocols_flag = NO;
BOOL match_flag = NO;
BOOL expand_frameworks_flag = NO;
BOOL sort_flag = NO;
BOOL sort_classes_flag = NO;

int swap_fat = 0;
int swap_macho = 0;

#define MAX_SECTIONS 2048

NSMutableArray *mappedFiles;
NSMutableDictionary *mappedFilesByInstallName;

char *current_filename = NULL;

struct section_info
{
    char *filename;
    char name[17];
    struct section *section;
    void *start;
    long vmaddr;
    long size;
} objc_sections[MAX_SECTIONS];

int section_count = 0;

//----------------------------------------------------------------------

#define SEC_CLASS          "__class"
#define SEC_SYMBOLS        "__symbols"
#define SEC_CSTRING        "__cstring"  /* In SEG_TEXT segments */
#define SEC_PROTOCOL       "__protocol"
#define SEC_CATEGORY       "__category"
#define SEC_CLS_METH       "__cls_meth"
#define SEC_INST_METH      "__inst_meth"
#define SEC_META_CLASS     "__meta_class"
#define SEC_CLASS_NAMES    "__class_names"
#define SEC_MODULE_INFO    "__module_info"
#define SEC_CAT_CLS_METH   "__cat_cls_meth"
#define SEC_INSTANCE_VARS  "__instance_vars"
#define SEC_CAT_INST_METH  "__cat_inst_meth"
#define SEC_METH_VAR_TYPES "__meth_var_types"
#define SEC_METH_VAR_NAMES "__meth_var_names"

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

NSMutableDictionary *protocols;

//======================================================================

void process_file (void *ptr, char *filename);

int process_macho (void *ptr, char *filename);
unsigned long process_load_command (void *start, void *ptr, char *filename);
void process_dylib_command (void *start, void *ptr);
void process_fvmlib_command (void *start, void *ptr);
void process_segment_command (void *start, void *ptr, char *filename);
void process_objc_segment (void *start, void *ptr, char *filename);

struct section_info *find_objc_section (char *name, char *filename);
void *translate_address_to_pointer (long addr, char *section);
void *translate_address_to_pointer_complain (long addr, char *section, BOOL complain);
char *string_at (long addr, char *section);
NSString *nsstring_at (long addr, char *section);

struct section_info *section_of_address (long addr);
NSArray *handle_objc_symtab (struct my_objc_symtab *symtab);
ObjcClass *handle_objc_class (struct my_objc_class *ocl);
ObjcCategory *handle_objc_category (struct my_objc_category *ocat);
NSArray *handle_objc_protocols (struct my_objc_protocol_list *plist, BOOL expandProtocols);
NSArray *handle_objc_meta_class (struct my_objc_class *ocl);
NSArray *handle_objc_ivars (struct my_objc_ivars *ivars);
NSArray *handle_objc_methods (struct my_objc_methods *methods, char ch);

void show_single_module (struct section_info *module_info);
void show_all_modules (void);
void build_up_objc_segments (char *filename);

//======================================================================

void process_file (void *ptr, char *filename)
{
    struct mach_header *mh = (struct mach_header *)ptr;
    struct fat_header *fh = (struct fat_header *)ptr;
    struct fat_arch *fa = (struct fat_arch *)(fh + 1);
    int l;
    int result = 1;

    if (mh->magic == FAT_CIGAM)
    {
        // Fat file... Other endian.

        swap_fat = 1;
        for (l = 0; l < NXSwapLong (fh->nfat_arch); l++)
        {
#ifdef VERBOSE
            printf ("archs: %ld\n", NXSwapLong (fh->nfat_arch));
            printf ("offset: %lx\n", NXSwapLong (fa->offset));
            printf ("arch: %08lx\n", NXSwapLong (fa->cputype));
#endif
            result = process_macho (ptr + NXSwapLong (fa->offset), filename);
            if (result == 0) 
                break;
            fa++;
        }
    }
    else if (mh->magic == FAT_MAGIC)
    {
        // Fat file... This endian.

        for (l = 0; l < fh->nfat_arch; l++)
        {
#ifdef VERBOSE
            printf ("archs: %ld\n", fh->nfat_arch);
            printf ("offset: %lx\n", fa->offset);
            printf ("arch: %08x\n", fa->cputype);
#endif
            result = process_macho (ptr + fa->offset, filename);
            if (result == 0) 
                break;
            fa++;
        }
    }
    else
    {
        result = process_macho (ptr, filename);
    }

    switch (result)
    {
      case 0:
          break;
          
      case 1:
          printf ("Error: File did not contain an executable with our endian.\n");
          break;

      default:
          printf ("Error: processing Mach-O file.\n");
    }
}

//----------------------------------------------------------------------

// Returns 0 if this was our endian, 1 if it was not, 2 otherwise.

int process_macho (void *ptr, char *filename)
{
    struct mach_header *mh = (struct mach_header *)ptr;
    int l;
    void *start = ptr;

    if (mh->magic == MH_CIGAM)
    {
        swap_macho = 1;
        return 1;
    }
    else if (mh->magic != MH_MAGIC)
    {
        printf ("This is not a Mach-O file.\n");
        return 2;
    }

    ptr += sizeof (struct mach_header);

    for (l = 0; l < mh->ncmds; l++)
    {
        ptr += process_load_command (start, ptr, filename);
    }

    return 0;
}

//----------------------------------------------------------------------

unsigned long process_load_command (void *start, void *ptr, char *filename)
{
    struct load_command *lc = (struct load_command *)ptr;

#ifdef VERBOSE
    if (lc->cmd <= LC_SUB_FRAMEWORK)
    {
        printf ("%s\n", load_command_names[ lc->cmd ]);
    }
    else
    {
        printf ("%08lx\n", lc->cmd);
    }
#endif

    if (lc->cmd == LC_SEGMENT)
    {
        process_segment_command (start, ptr, filename);
    }
    else if (lc->cmd == LC_LOAD_DYLIB)
    {
        process_dylib_command (start, ptr);
    }
    else if (lc->cmd == LC_LOADFVMLIB)
    {
        process_fvmlib_command (start, ptr);
    }

    return lc->cmdsize;
}

//----------------------------------------------------------------------

void process_dylib_command (void *start, void *ptr)
{
    struct dylib_command *dc = (struct dylib_command *)ptr;

    build_up_objc_segments (ptr + dc->dylib.name.offset);
}

//----------------------------------------------------------------------

void process_fvmlib_command (void *start, void *ptr)
{
    struct fvmlib_command *fc = (struct fvmlib_command *)ptr;

    build_up_objc_segments (ptr + fc->fvmlib.name.offset);
}

//----------------------------------------------------------------------

void process_segment_command (void *start, void *ptr, char *filename)
{
    struct segment_command *sc = (struct segment_command *)ptr;
    char name[17];
  
    strncpy (name, sc->segname, 16);
    name[16] = 0;

    if (!strcmp (name, SEG_OBJC) || 
        !strcmp (name, SEG_TEXT) || /* for MacOS X __cstring sections */
        !strcmp (name, "") /* for .o files. */)
    {
        process_objc_segment (start, ptr, filename);
    }
}

//----------------------------------------------------------------------

void process_objc_segment (void *start, void *ptr, char *filename)
{
    struct segment_command *sc = (struct segment_command *)ptr;
    struct section *section = (struct section *)(sc + 1);
    int l;

    for (l = 0; l < sc->nsects; l++)
    {
        if (section_count >= MAX_SECTIONS)
        {
            printf ("Error: Maximum number of sections reached.\n");
            return;
        }

        objc_sections[section_count].filename = filename;
        strncpy (objc_sections[section_count].name, section->sectname, 16);
        objc_sections[section_count].name[16] = 0;
        objc_sections[section_count].section = section;
        objc_sections[section_count].start = start + section->offset;
        objc_sections[section_count].vmaddr = section->addr;
        objc_sections[section_count].size = section->size;
        if (!strcmp(section->segname, SEG_OBJC) ||
              (!strcmp(section->segname, SEG_TEXT) &&
               !strcmp(section->sectname, SEC_CSTRING)))
        {
            section_count++;
        }
        section++;
    }
}

//----------------------------------------------------------------------

// Find the Objective-C segment for the given filename noted in our
// list.

struct section_info *find_objc_section (char *name, char *filename)
{
    int l;

    for (l = 0; l < section_count; l++)
    {
        if (!strcmp (name, objc_sections[l].name) && !strcmp (filename, objc_sections[l].filename))
        {
            return &objc_sections[l];
        }
    }

    return NULL;
}

//----------------------------------------------------------------------

void debug_section_overlap (void)
{
    int l;

    for (l = 0; l < section_count; l++)
    {
        printf ("%10ld to %10ld [size 0x%08ld] %-16s of %s\n",
                objc_sections[l].vmaddr, objc_sections[l].vmaddr + objc_sections[l].size, objc_sections[l].size,
                objc_sections[l].name, objc_sections[l].filename);
    }
}

//----------------------------------------------------------------------

//
// Take a long from the Mach-O file (which is really a pointer when
// the section is loaded at the proper location) and translate it into
// a pointer to where we have the file mapped.
//

void *translate_address_to_pointer (long addr, char *section)
{
    return translate_address_to_pointer_complain (addr, section, YES);
}

void *translate_address_to_pointer_complain (long addr, char *section, BOOL complain)
{
    int l;
    int count = 0;

    for (l = 0; l < section_count; l++)
    {
        if (addr >= objc_sections[l].vmaddr && addr < objc_sections[l].vmaddr + objc_sections[l].size
            && !strcmp (objc_sections[l].name, section))
        {
            count++;
        }
    }

    if (count > 1)
    {
        // If there are still duplicates, we choose the one for the current file.
        for (l = 0; l < section_count; l++)
        {
            if (addr >= objc_sections[l].vmaddr && addr < objc_sections[l].vmaddr + objc_sections[l].size
                && !strcmp (objc_sections[l].name, section)
                && !strcmp (objc_sections[l].filename, current_filename))
            {
                return objc_sections[l].start + addr - objc_sections[l].vmaddr;
            }
        }
    }
    else
    {
        for (l = 0; l < section_count; l++)
        {
            if (addr >= objc_sections[l].vmaddr && addr < objc_sections[l].vmaddr + objc_sections[l].size
                && !strcmp (objc_sections[l].name, section))
            {
                return objc_sections[l].start + addr - objc_sections[l].vmaddr;
            }
        }
    }

    if (addr != 0 && complain)
        printf ("address (0x%08lx) not in '%s' section of OBJC segment!\n", addr, section);

    return NULL;
}

//----------------------------------------------------------------------

char *string_at (long addr, char *section)
{
    /* String addresses are located in a different section in MacOS X binaries.
       Look there first, and only print error message if not found in either
       the old or new style section.  MacOS X still supports older Mac OS X
       Server binaries, so we do need to look in both places.
     */
    char *ptr = (char *)translate_address_to_pointer_complain (addr, SEC_CSTRING, NO);
    if (ptr == NULL)
	ptr = (char *)translate_address_to_pointer_complain (addr, section, YES);
    return ptr;
}

//----------------------------------------------------------------------

NSString *nsstring_at (long addr, char *section)
{
    char *str = string_at (addr, section);
    return (str == NULL) ? (NSString *)@"" : [NSString stringWithCString:str];
}

//----------------------------------------------------------------------

struct section_info *section_of_address (long addr)
{
    int l;

    for (l = 0; l < section_count; l++)
    {
        if (addr >= objc_sections[l].vmaddr && addr < objc_sections[l].vmaddr + objc_sections[l].size)
        {
            return &objc_sections[l];
        }
    }

    return NULL;
}

//======================================================================

NSArray *handle_objc_symtab (struct my_objc_symtab *symtab)
{
    NSMutableArray *classList = [NSMutableArray array];
    ObjcThing *objcThing;
    long *class_pointer;
    int l;
  
    if (symtab == NULL)
    {
        printf ("NULL symtab...\n");
        return nil;
    }

    class_pointer = &symtab->class_pointer;

    for (l = 0; l < symtab->cls_def_count; l++)
    {
        objcThing = handle_objc_class (translate_address_to_pointer (*class_pointer, SEC_CLASS));
        if (objcThing != nil)
            [classList addObject:objcThing];

        class_pointer++;
    }

    for (l = 0; l < symtab->cat_def_count; l++)
    {
        objcThing = handle_objc_category (translate_address_to_pointer (*class_pointer, SEC_CATEGORY));
        if (objcThing != nil)
            [classList addObject:objcThing];

        class_pointer++;
    }

    return classList;
}

//----------------------------------------------------------------------

ObjcClass *handle_objc_class (struct my_objc_class *ocl)
{
    ObjcClass *objcClass;
    NSArray *tmp;
    
    if (ocl == NULL)
        return nil;

    tmp = handle_objc_protocols ((struct my_objc_protocol_list *)translate_address_to_pointer (ocl->protocols, SEC_CAT_CLS_METH), YES);

    if (string_at (ocl->super_class, SEC_CLASS_NAMES) == NULL)
    {
        objcClass = [[[ObjcClass alloc] initWithClassName:nsstring_at (ocl->name, SEC_CLASS_NAMES) superClassName:nil] autorelease];
    }
    else
    {
        objcClass = [[[ObjcClass alloc] initWithClassName:nsstring_at (ocl->name, SEC_CLASS_NAMES)
                                        superClassName:nsstring_at (ocl->super_class, SEC_CLASS_NAMES)] autorelease];
    }

    [objcClass addProtocolNames:tmp];

    tmp = handle_objc_ivars ((struct my_objc_ivars *)translate_address_to_pointer (ocl->ivars, SEC_INSTANCE_VARS));
    [objcClass addIvars:tmp];

    tmp = handle_objc_meta_class ((struct my_objc_class *)translate_address_to_pointer (ocl->isa, SEC_META_CLASS));
    [objcClass addClassMethods:tmp];

    tmp = handle_objc_methods ((struct my_objc_methods *)translate_address_to_pointer (ocl->methods, SEC_INST_METH), '-');
    [objcClass addInstanceMethods:tmp];

    return objcClass;
}

//----------------------------------------------------------------------

ObjcCategory *handle_objc_category (struct my_objc_category *ocat)
{
    ObjcCategory *objcCategory;
    NSArray *tmp;
    
    if (ocat == NULL)
        return nil;
  
    objcCategory = [[[ObjcCategory alloc] initWithClassName:nsstring_at (ocat->class_name, SEC_CLASS_NAMES)
                                          categoryName:nsstring_at (ocat->category_name, SEC_CLASS_NAMES)] autorelease];

    tmp = handle_objc_methods ((struct my_objc_methods *)translate_address_to_pointer (ocat->class_methods, SEC_CAT_CLS_METH), '+');
    [objcCategory addClassMethods:tmp];

    tmp = handle_objc_methods ((struct my_objc_methods *)translate_address_to_pointer (ocat->methods, SEC_CAT_INST_METH), '-');
    [objcCategory addInstanceMethods:tmp];

    return objcCategory;
}

//----------------------------------------------------------------------

// Return list of protocol names.
NSArray *handle_objc_protocols (struct my_objc_protocol_list *plist, BOOL expandProtocols)
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
        prot = translate_address_to_pointer (*ptr, SEC_PROTOCOL);

        objcProtocol = [[[ObjcProtocol alloc] initWithProtocolName:nsstring_at (prot->protocol_name, SEC_CLASS_NAMES)] autorelease];
        [protocolArray addObject:[objcProtocol protocolName]];

        parentProtocols = handle_objc_protocols (translate_address_to_pointer (prot->protocol_list, SEC_CAT_CLS_METH),
                                                 expand_protocols_flag);
        [objcProtocol addProtocolNames:parentProtocols];

        mlist = translate_address_to_pointer (prot->instance_methods, SEC_CAT_INST_METH);
        if (mlist != NULL)
        {
            meth = (struct my_objc_prot_inst_meth *)&mlist->methods;

            for (l = 0; l < mlist->count; l++)
            {
                [objcProtocol addProtocolMethod:[[[ObjcMethod alloc] initWithMethodName:nsstring_at (meth->name, SEC_METH_VAR_NAMES)
                                                                     type:nsstring_at (meth->types, SEC_METH_VAR_TYPES)] autorelease]];
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

NSArray *handle_objc_meta_class (struct my_objc_class *ocl)
{
    if (ocl == NULL)
        return nil;

    return handle_objc_methods ((struct my_objc_methods *)translate_address_to_pointer (ocl->methods, SEC_CLS_METH), '+');
}  

//----------------------------------------------------------------------

NSArray *handle_objc_ivars (struct my_objc_ivars *ivars)
{
    struct my_objc_ivar *ivar = (struct my_objc_ivar *)(ivars + 1);
    NSMutableArray *ivarArray = [NSMutableArray array];
    ObjcIvar *objcIvar;
    int l;

    if (ivars == NULL)
        return nil;

    for (l = 0; l < ivars->ivar_count; l++)
    {
        objcIvar = [[[ObjcIvar alloc] initWithName:nsstring_at (ivar->name, SEC_METH_VAR_NAMES)
                                      type:nsstring_at (ivar->type, SEC_METH_VAR_TYPES)
                                      offset:ivar->offset] autorelease];
        [ivarArray addObject:objcIvar];

        ivar++;
    }

    return ivarArray;
}

//----------------------------------------------------------------------

NSArray *handle_objc_methods (struct my_objc_methods *methods, char ch)
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
            objcMethod = [[[ObjcMethod alloc] initWithMethodName:nsstring_at (method->name, SEC_METH_VAR_NAMES)
                                              type:nsstring_at (method->types, SEC_METH_VAR_TYPES)
                                              address:method->imp] autorelease];
            [methodArray addObject:objcMethod];
        }
        method++;
    }

    return methodArray;
}

//======================================================================

void show_single_module (struct section_info *module_info)
{
    struct my_objc_module *m;
    int module_count;
    int l;
    char *tmp;
    id en, thing, key;
    NSMutableArray *classList = [NSMutableArray array];
    NSArray *newClasses;
    int flags = 0;

    if (module_info == NULL)
    {
        return;
    }

    if (sort_flag == YES)
        flags |= F_SORT_METHODS;

    if (show_ivar_offsets_flag == YES)
        flags |= F_SHOW_IVAR_OFFSET;

    if (show_method_addresses_flag == YES)
        flags |= F_SHOW_METHOD_ADDRESS;

    tmp = current_filename;
    m = module_info->start;
    module_count = module_info->size / sizeof (struct my_objc_module);

    {
        MappedFile *currentFile;
        NSString *installName, *filename;
        NSString *key;
        
#ifdef USE_FILE_SYSTEM_REPRESENTATION
        key = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:module_info->filename length:strlen(module_info->filename)];
#else
        key = [NSString stringWithCString:module_info->filename];
#endif
        currentFile = [mappedFilesByInstallName objectForKey:key];
        installName = [currentFile installName];
        filename = [currentFile filename];
        if (filename == nil || [installName isEqual:filename] == YES)
        {
            printf ("\n/*\n * File: %s\n */\n\n", module_info->filename);
        }
        else
        {
#ifdef USE_FILE_SYSTEM_REPRESENTATION
            printf ("\n/*\n * File: %s\n * Install name: %s\n */\n\n", [filename fileSystemRepresentation], module_info->filename);
#else
            printf ("\n/*\n * File: %s\n * Install name: %s\n */\n\n", [filename cString], module_info->filename);
#endif
        }
    }
    current_filename = module_info->filename;

    for (l = 0; l < module_count; l++)
    {
        newClasses = handle_objc_symtab ((struct my_objc_symtab *)translate_address_to_pointer (m->symtab, SEC_SYMBOLS));
        [classList addObjectsFromArray:newClasses];
        m++;
    }


    if (sort_flag == YES)
        en = [[[protocols allKeys] sortedArrayUsingSelector:@selector (compare:)] objectEnumerator];
    else
        en = [[protocols allKeys] objectEnumerator];

    while (key = [en nextObject])
    {
        thing = [protocols objectForKey:key];
        if (match_flag == NO || RE_EXEC ([[thing sortableName] cString]) == 1)
            [thing showDefinition:flags];
    }

    if (sort_flag == YES && sort_classes_flag == NO)
        en = [[classList sortedArrayUsingSelector:@selector (orderByName:)] objectEnumerator];
    else if (sort_classes_flag == YES)
        en = [[ObjcClass sortedClasses] objectEnumerator];
    else
        en = [classList objectEnumerator];


    while (thing = [en nextObject])
    {
        if (match_flag == NO || RE_EXEC ([[thing sortableName] cString]) == 1)
            [thing showDefinition:flags];
    }

    [protocols removeAllObjects];

    current_filename = tmp;
}

//----------------------------------------------------------------------

void show_all_modules (void)
{
    int l;

    for (l = section_count - 1; l >= 0; l--)
    {
        if (!strcmp (objc_sections[l].name, SEC_MODULE_INFO))
        {
            show_single_module ((struct section_info *)&objc_sections[l]);
        }
    }
}

//----------------------------------------------------------------------

void build_up_objc_segments (char *filename)
{    
    MappedFile *mappedFile;
    NSEnumerator *mfEnumerator;
    NSString *aFilename;

    // Only process each file once.

    mfEnumerator = [mappedFiles objectEnumerator];
    while (mappedFile = [mfEnumerator nextObject])
    {
#ifdef USE_FILE_SYSTEM_REPRESENTATION
        if (!strcmp (filename, [[mappedFile installName] fileSystemRepresentation]))
            return;
#else
        if (!strcmp (filename, [[mappedFile installName] cString]))
            return;
#endif
    }

#ifdef USE_FILE_SYSTEM_REPRESENTATION
    aFilename = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:filename length:strlen(filename)];
#else
    aFilename = [NSString stringWithCString:filename];
#endif
    mappedFile = [[[MappedFile alloc] initWithFilename:aFilename] autorelease];
    if (mappedFile != nil)
    {
        [mappedFiles addObject:mappedFile];
        [mappedFilesByInstallName setObject:mappedFile forKey:[mappedFile installName]];

        process_file ((void *)[mappedFile data], filename);
    }
}

//----------------------------------------------------------------------

void print_usage (void)
{
    fprintf (stderr,
             "class-dump %s\n"
             "Usage: class-dump [-a] [-A] [-e] [-R] [-C regex] [-r] [-s] [-S] executable-file\n"
             "        -a  show instance variable offsets\n"
             "        -A  show implementation addresses\n"
             "        -e  expand structure (and union) definition whenever possible\n"
             "        -I  sort by inheritance (overrides -S)\n"
             "        -R  recursively expand @protocol <>\n"
             "        -C  only display classes matching regular expression\n"
             "        -r  recursively expand frameworks and fixed VM shared libraries\n"
             "        -s  convert STR to char *\n"
             "        -S  sort protocols, classes, and methods\n",
             CLASS_DUMP_VERSION
       );
}

//----------------------------------------------------------------------

void print_header (void)
{
    printf (
        "/*\n"
        " *     Generated by class-dump (version %s).\n"
        " *\n"
        " *     class-dump is Copyright (C) 1997, 1999-2002 by Steve Nygard.\n"
        " */\n", CLASS_DUMP_VERSION
       );
}

//======================================================================

int main (int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    int c;
    extern int optind;
    extern char *optarg;
    int error_flag = 0;
    const char *tmp;
  
    if (argc == 1)
    {
        print_usage();
        exit (2);
    }

    while ( (c = getopt (argc, argv, "aAeIRC:rsS")) != EOF)
    {
        switch (c)
        {
          case 'a':
              show_ivar_offsets_flag = YES;
              break;
        
          case 'A':
              show_method_addresses_flag = YES;
              break;
        
          case 'e':
              expand_structures_flag = 1;
              break;
        
          case 'R':
              expand_protocols_flag = YES;
              break;
        
          case 'C':
              if (match_flag == YES)
              {
                  printf ("Error: sorry, only one -C allowed\n");
                  error_flag++;
              }
              else
              {
                  match_flag = YES;

                  tmp = RE_COMP (optarg);
                  if (tmp != NULL)
                  {
                      printf ("Error: %s\n", tmp);
                      exit (1);
                  }
              }
              break;
        
          case 'r':
              expand_frameworks_flag = YES;
              break;
        
          case 's':
              char_star_flag = 1;
              break;
        
          case 'S':
              sort_flag = YES;
              break;

          case 'I':
              sort_classes_flag = YES;
              break;
              
          case '?':
          default:
              error_flag++;
              break;
        }
    }

    if (error_flag > 0)
    {
        print_usage ();
        exit (2);
    }

    mappedFiles = [NSMutableArray array];
    mappedFilesByInstallName = [NSMutableDictionary dictionary];
    protocols = [NSMutableDictionary dictionary];

    if (optind < argc)
    {
        build_up_objc_segments (argv[optind]);

        print_header ();

        //debug_section_overlap ();

        if (section_count > 0)
        {
            if (expand_frameworks_flag == NO)
                show_single_module ((struct section_info *)find_objc_section (SEC_MODULE_INFO, argv[optind]));
            else
                show_all_modules ();
        }
    }

    [mappedFiles removeAllObjects];

    [pool release];

    return 0;
}
