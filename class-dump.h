//
// $Id: class-dump.h,v 1.5 2003/02/21 06:04:14 nygard Exp $
//

//
//  This file is a part of class-dump v2, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997, 2000  Steve Nygard
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

#import <Foundation/NSObject.h>
#include <regex.h>

struct my_objc_module
{
    long version;
    long size;
    long name;
    long symtab;
};

// Section: __symbols
struct my_objc_symtab
{
    long sel_ref_cnt;
    long refs;
    short cls_def_count;
    short cat_def_count;
    long class_pointer;
};

// Section: __class
struct my_objc_class
{
    long isa;
    long super_class;
    long name;
    long version;
    long info;
    long instance_size;
    long ivars;
    long methods;
    long cache;
    long protocols;
};

// Section: ??
struct my_objc_category
{
    long category_name;
    long class_name;
    long methods;
    long class_methods;
    long protocols;
};

// Section: __instance_vars
struct my_objc_ivars
{
    long ivar_count;
    // Followed by ivars
};

// Section: __instance_vars
struct my_objc_ivar
{
    long name;
    long type;
    long offset;
};

// Section: __inst_meth
struct my_objc_methods
{
    long _obsolete;
    long method_count;
    // Followed by methods
};

// Section: __inst_meth
struct my_objc_method
{
    long name;
    long types;
    long imp;
};

// Section: __meta_class
struct my_objc_isa
{
};

struct my_objc_protocol_list
{
    long next;
    long count;
    long list;
};

struct my_objc_protocol
{
    long isa;
    long protocol_name;
    long protocol_list;
    long instance_methods;
};

struct my_objc_prot_inst_meth
{
    long name;
    long types;
};

struct my_objc_prot_inst_meth_list
{
    long count;
    long methods;
};

//======================================================================

@class NSArray, NSString, NSMutableArray, NSMutableDictionary;
@class MappedFile, ObjcClass, ObjcCategory;

@interface CDSectionInfo : NSObject
{
    NSString *filename;
    NSString *name;
    struct section *section;
    void *start;
    long vmaddr;
    long size;
}

- (id)initWithFilename:(NSString *)aFilename
                  name:(NSString *)aName
               section:(struct section *)aSection
                 start:(void *)aStart
                vmaddr:(long)aVMAddr
                  size:(long)aSize;
- (void)dealloc;

- (NSString *)filename;
- (NSString *)name;
- (struct section *)section;
- (void *)start;
- (long)vmaddr;
- (long)size;

- (NSString *)description;
- (BOOL)containsAddress:(long)anAddress;
- (void *)translateAddress:(long)anAddress;

@end

@interface CDClassDump : NSObject
{
    NSString *mainPath;

    NSMutableArray *mappedFiles;
    NSMutableDictionary *mappedFilesByInstallName;
    NSMutableArray *sections;

    struct {
        unsigned int shouldShowIvarOffsets:1;
        unsigned int shouldShowMethodAddresses:1;
        unsigned int shouldExpandProtocols:1;
        unsigned int shouldMatchRegex:1;
        unsigned int shouldSort:1;
        unsigned int shouldSortClasses:1;

        // Not really used yet:
        unsigned int shouldSwapFat:1;
        unsigned int shouldSwapMachO:1;
    } flags;

    regex_t compiledRegex;
}

- (id)initWithPath:(NSString *)aPath;
- (void)dealloc;

- (BOOL)shouldShowIvarOffsets;
- (void)setShouldShowIvarOffsets:(BOOL)newFlag;

- (BOOL)shouldShowMethodAddresses;
- (void)setShouldShowMethodAddresses:(BOOL)newFlag;

- (BOOL)shouldExpandProtocols;
- (void)setShouldExpandProtocols:(BOOL)newFlag;

- (BOOL)shouldSort;
- (void)setShouldSort:(BOOL)newFlag;

- (BOOL)shouldSortClasses;
- (void)setShouldSortClasses:(BOOL)newFlag;

- (BOOL)shouldMatchRegex;
- (void)setShouldMatchRegex:(BOOL)newFlag;

- (BOOL)setRegex:(char *)regexCString errorMessage:(NSString **)errorMessagePointer;
- (BOOL)regexMatchesCString:(const char *)str;

- (NSArray *)sections;
- (void)addSectionInfo:(CDSectionInfo *)aSectionInfo;





- (void)processFile:(MappedFile *)aMappedFile;

- (int)processMachO:(void *)ptr filename:(NSString *)filename;
- (unsigned long)processLoadCommand:(void *)start ptr:(void *)ptr filename:(NSString *)filename;
- (void)processDylibCommand:(void *)start ptr:(void *)ptr;
- (void)processFvmlibCommand:(void *)start ptr:(void *)ptr;
- (void)processSegmentCommand:(void *)start ptr:(void *)ptr filename:(NSString *)filename;
- (void)processObjectiveCSegment:(void *)start ptr:(void *)ptr filename:(NSString *)filename;

// TODO: Objc -> ObjectiveC
- (NSArray *)handleObjcSymtab:(struct my_objc_symtab *)symtab;
- (ObjcClass *)handleObjcClass:(struct my_objc_class *)ocl;
- (ObjcCategory *)handleObjcCategory:(struct my_objc_category *)ocat;
- (NSArray *)handleObjcProtocols:(struct my_objc_protocol_list *)plist expandProtocols:(BOOL)expandProtocols;
- (NSArray *)handleObjcMetaClass:(struct my_objc_class *)ocl;
- (NSArray *)handleObjcIvars:(struct my_objc_ivars *)ivars;
- (NSArray *)handleObjcMethods:(struct my_objc_methods *)methods methodType:(char)ch;

- (void)showSingleModule:(CDSectionInfo *)moduleInfo;
- (void)showAllModules;
- (void)buildUpObjectiveCSegments:(NSString *)filename;

// Utility methods
- (CDSectionInfo *)objectiveCSectionWithName:(NSString *)name filename:(NSString *)filename;
- (void)debugSectionOverlap;
- (void *)translateAddressToPointer:(long)addr section:(NSString *)section;
- (void *)translateAddressToPointerComplain:(long)addr section:(NSString *)section complain:(BOOL)complain;
- (char *)stringAt:(long)addr section:(NSString *)section;
- (NSString *)nsstringAt:(long)addr section:(NSString *)section;
- (CDSectionInfo *)sectionOfAddress:(long)addr;

- (int)methodFormattingFlags;

@end
