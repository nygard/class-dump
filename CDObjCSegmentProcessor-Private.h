//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2007  Steve Nygard

#import "CDObjCSegmentProcessor.h"

// Section: __module_info
struct cd_objc_module {
    unsigned long version;
    unsigned long size;
    unsigned long name;
    unsigned long symtab;
};

// Section: __symbols
struct cd_objc_symtab
{
    long sel_ref_cnt;
    long refs; // not used until runtime?
    short cls_def_count;
    short cat_def_count;
    //long class_pointer;
};

// Section: __class
struct cd_objc_class
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
struct cd_objc_category
{
    long category_name;
    long class_name;
    long methods;
    long class_methods;
    long protocols;
};

// Section: __instance_vars
struct cd_objc_ivar_list
{
    long ivar_count;
    // Followed by ivars
};

// Section: __instance_vars
struct cd_objc_ivar
{
    long name;
    long type;
    int offset;
};

// Section: __inst_meth
struct cd_objc_method_list
{
    long _obsolete;
    long method_count;
    // Followed by methods
};

// Section: __inst_meth
struct cd_objc_method
{
    long name;
    long types;
    long imp;
};


struct cd_objc_protocol_list
{
    long next;
    long count;
    //long list;
};

struct cd_objc_protocol
{
    long isa;
    long protocol_name;
    long protocol_list;
    long instance_methods;
    long class_methods;
};

struct cd_objc_protocol_method_list
{
    long method_count;
    // Followed by methods
};

struct cd_objc_protocol_method
{
    long name;
    long types;
};

void swap_cd_objc_module(struct cd_objc_module *cd_objc_module);
void swap_cd_objc_symtab(struct cd_objc_symtab *cd_objc_symtab);
void swap_cd_objc_class(struct cd_objc_class *cd_objc_class);
void swap_cd_objc_category(struct cd_objc_category *cd_objc_category);
void swap_cd_objc_ivar_list(struct cd_objc_ivar_list *cd_objc_ivar_list);
void swap_cd_objc_ivar(struct cd_objc_ivar *cd_objc_ivar);
void swap_cd_objc_method_list(struct cd_objc_method_list *cd_objc_method_list);
void swap_cd_objc_method(struct cd_objc_method *cd_objc_method);
void swap_cd_objc_protocol_list(struct cd_objc_protocol_list *cd_objc_protocol_list);
void swap_cd_objc_protocol(struct cd_objc_protocol *cd_objc_protocol);
void swap_cd_objc_protocol_method_list(struct cd_objc_protocol_method_list *cd_objc_protocol_method_list);
void swap_cd_objc_protocol_method(struct cd_objc_protocol_method *cd_objc_protocol_method);

@class NSArray;
@class CDOCCategory, CDOCClass, CDOCProtocol, CDOCSymtab;

@interface CDObjCSegmentProcessor (Private)

- (void)processModules;
- (CDOCSymtab *)processSymtab:(unsigned long)symtab;
- (CDOCClass *)processClassDefinition:(unsigned long)defRef;
- (NSArray *)processProtocolList:(unsigned long)protocolListAddr;
- (CDOCProtocol *)processProtocol:(unsigned long)protocolAddr;
- (NSArray *)processProtocolMethods:(unsigned long)methodsAddr;
- (NSArray *)processMethods:(unsigned long)methodsAddr;
- (CDOCCategory *)processCategoryDefinition:(unsigned long)defRef;

- (void)processProtocolSection;
- (void)checkUnreferencedProtocols;

@end
