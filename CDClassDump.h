#import <Foundation/NSObject.h>

@class CDMachOFile;
@class CDOCClass;

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


// Section: __instance_vars
struct cd_objc_ivars
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
struct cd_objc_methods // TODO (2003-12-07): Rename method_list?
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
};

@interface CDClassDump2 : NSObject
{
    CDMachOFile *machOFile;
}

- (id)initWithMachOFile:(CDMachOFile *)aMachOFile;
- (void)dealloc;

- (void)doSomething;

- (void)processModules;
- (void)processSymtab:(unsigned long)symtab;
- (CDOCClass *)processClassDefinition:(unsigned long)defRef;
- (void)processCategoryDefinition:(unsigned long)defRef;

@end
