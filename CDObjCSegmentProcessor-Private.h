// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2007  Steve Nygard

#import "CDObjCSegmentProcessor.h"

// Section: __module_info
struct cd_objc_module {
    uint32_t version;
    uint32_t size;
    uint32_t name;
    uint32_t symtab;
};

// Section: __symbols
struct cd_objc_symtab
{
    uint32_t sel_ref_cnt;
    uint32_t refs; // not used until runtime?
    uint16_t cls_def_count;
    uint16_t cat_def_count;
    //long class_pointer;
};

// Section: __class
struct cd_objc_class
{
    uint32_t isa;
    uint32_t super_class;
    uint32_t name;
    uint32_t version;
    uint32_t info;
    uint32_t instance_size;
    uint32_t ivars;
    uint32_t methods;
    uint32_t cache;
    uint32_t protocols;
};

// Section: ??
struct cd_objc_category
{
    uint32_t category_name;
    uint32_t class_name;
    uint32_t methods;
    uint32_t class_methods;
    uint32_t protocols;
};

// Section: __instance_vars
struct cd_objc_ivar_list
{
    uint32_t ivar_count;
    // Followed by ivars
};

// Section: __instance_vars
struct cd_objc_ivar
{
    uint32_t name;
    uint32_t type;
    uint32_t offset;
};

// Section: __inst_meth
struct cd_objc_method_list
{
    uint32_t _obsolete;
    uint32_t method_count;
    // Followed by methods
};

// Section: __inst_meth
struct cd_objc_method
{
    uint32_t name;
    uint32_t types;
    uint32_t imp;
};


struct cd_objc_protocol_list
{
    uint32_t next;
    uint32_t count;
    //uint32_t list;
};

struct cd_objc_protocol
{
    uint32_t isa;
    uint32_t protocol_name;
    uint32_t protocol_list;
    uint32_t instance_methods;
    uint32_t class_methods;
};

struct cd_objc_protocol_method_list
{
    uint32_t method_count;
    // Followed by methods
};

struct cd_objc_protocol_method
{
    uint32_t name;
    uint32_t types;
};

@class NSArray;
@class CDOCCategory, CDOCClass, CDOCProtocol, CDOCSymtab;

@interface CDObjCSegmentProcessor (Private)

- (void)processModules;
- (CDOCSymtab *)processSymtabAtAddress:(uint32_t)address;
- (CDOCClass *)processClassDefinitionAtAddress:(uint32_t)address;
- (NSArray *)uniquedProtocolListAtAddress:(uint32_t)address;
- (NSArray *)processMethodsAtAddress:(uint32_t)address;
- (NSArray *)processMethodsAtAddress:(uint32_t)address isFromProtocolDefinition:(BOOL)isFromProtocolDefinition;
- (CDOCCategory *)processCategoryDefinitionAtAddress:(uint32_t)address;
- (CDOCProtocol *)protocolAtAddress:(uint32_t)address;

- (void)processProtocolSection;
- (void)checkUnreferencedProtocols;

@end
