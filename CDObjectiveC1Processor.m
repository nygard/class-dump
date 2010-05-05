// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDObjectiveC1Processor.h"

#include <mach-o/arch.h>

#import "CDClassDump.h"
#import "CDLCDylib.h"
#import "CDMachOFile.h"
#import "CDOCCategory.h"
#import "CDOCClass.h"
#import "CDOCIvar.h"
#import "CDOCMethod.h"
#import "CDOCModule.h"
#import "CDOCProtocol.h"
#import "CDOCSymtab.h"
#import "CDSection32.h"
#import "CDLCSegment32.h"
#import "NSArray-Extensions.h"
#import "CDVisitor.h"


#import "CDSection.h"
#import "CDLCSegment.h"

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

static BOOL debug = NO;

@implementation CDObjectiveC1Processor

- (id)initWithMachOFile:(CDMachOFile *)aMachOFile;
{
    if ([super initWithMachOFile:aMachOFile] == nil)
        return nil;

    modules = [[NSMutableArray alloc] init];

    return self;
}

- (void)dealloc;
{
    [modules release];

    [super dealloc];
}

- (void)process;
{
    if ([machOFile isEncrypted] == NO && [machOFile canDecryptAllSegments]) {
        [super process];

        [self processModules];
    }
}

//
// Formerly private
//

- (void)processModules;
{
    CDLCSegment *objcSegment;
    CDSection *moduleSection;
    NSData *sectionData;
    CDDataCursor *cursor;

    objcSegment = [machOFile segmentWithName:@"__OBJC"];
    moduleSection = [objcSegment sectionWithName:@"__module_info"];
    sectionData = [moduleSection data];

    cursor = [[CDDataCursor alloc] initWithData:sectionData];
    [cursor setByteOrder:[machOFile byteOrder]];
    while ([cursor isAtEnd] == NO) {
        struct cd_objc_module objcModule;
        CDOCModule *module;
        NSString *name;
        NSArray *array;

        objcModule.version = [cursor readInt32];
        objcModule.size = [cursor readInt32];
        objcModule.name = [cursor readInt32];
        objcModule.symtab = [cursor readInt32];

        //NSLog(@"objcModule.size: %u", objcModule.size);
        //NSLog(@"sizeof(struct cd_objc_module): %u", sizeof(struct cd_objc_module));
        assert(objcModule.size == sizeof(struct cd_objc_module)); // Because this is what we're assuming.

        name = [machOFile stringAtAddress:objcModule.name];
        if (name != nil && [name length] > 0 && debug)
            NSLog(@"Note: a module name is set: %@", name);

        //NSLog(@"%08x %08x %08x %08x - '%@'", objcModule.version, objcModule.size, objcModule.name, objcModule.symtab, name);
        //NSLog(@"\tsect: %@", [[machOFile segmentContainingAddress:objcModule.name] sectionContainingAddress:objcModule.name]);
        //NSLog(@"symtab: %08x", objcModule.symtab);

        module = [[CDOCModule alloc] init];
        [module setVersion:objcModule.version];
        [module setName:[machOFile stringAtAddress:objcModule.name]];
        [module setSymtab:[self processSymtabAtAddress:objcModule.symtab]];
        [modules addObject:module];

        array = [[module symtab] classes];
        if (array != nil)
            [classes addObjectsFromArray:array];

        array = [[module symtab] categories];
        if (array != nil)
            [categories addObjectsFromArray:array];

        [module release];
    }

    [cursor release];
}

- (CDOCSymtab *)processSymtabAtAddress:(uint32_t)address;
{
    CDDataCursor *cursor;
    struct cd_objc_symtab objcSymtab;
    CDOCSymtab *aSymtab = nil;
    unsigned int index;

    //----------------------------------------

    cursor = [[CDDataCursor alloc] initWithData:[machOFile data]];
    [cursor setByteOrder:[machOFile byteOrder]];
    [cursor setOffset:[machOFile dataOffsetForAddress:address segmentName:@"__OBJC"]];
    //[cursor setOffset:[machOFile dataOffsetForAddress:address]];
    //NSLog(@"cursor offset: %08x", [cursor offset]);
    if ([cursor offset] != 0) {
        objcSymtab.sel_ref_cnt = [cursor readInt32];
        objcSymtab.refs = [cursor readInt32];
        objcSymtab.cls_def_count = [cursor readInt16];
        objcSymtab.cat_def_count = [cursor readInt16];
        //NSLog(@"[@ %08x]: %08x %08x %04x %04x", address, objcSymtab.sel_ref_cnt, objcSymtab.refs, objcSymtab.cls_def_count, objcSymtab.cat_def_count);

        aSymtab = [[[CDOCSymtab alloc] init] autorelease];

        for (index = 0; index < objcSymtab.cls_def_count; index++) {
            CDOCClass *aClass;
            uint32_t val;

            val = [cursor readInt32];
            //NSLog(@"%4d: %08x", index, val);

            aClass = [self processClassDefinitionAtAddress:val];
            if (aClass != nil)
                [aSymtab addClass:aClass];
        }

        for (index = 0; index < objcSymtab.cat_def_count; index++) {
            CDOCCategory *aCategory;
            uint32_t val;

            val = [cursor readInt32];
            //NSLog(@"%4d: %08x", index, val);

            aCategory = [self processCategoryDefinitionAtAddress:val];
            if (aCategory != nil)
                [aSymtab addCategory:aCategory];
        }
    }

    [cursor release];

    return aSymtab;
}

- (CDOCClass *)processClassDefinitionAtAddress:(uint32_t)address;
{
    CDDataCursor *cursor;
    struct cd_objc_class objcClass;
    CDOCClass *aClass;
    NSString *name;

    cursor = [[CDDataCursor alloc] initWithData:[machOFile data]];
    [cursor setByteOrder:[machOFile byteOrder]];
    [cursor setOffset:[machOFile dataOffsetForAddress:address]];

    objcClass.isa = [cursor readInt32];
    objcClass.super_class = [cursor readInt32];
    objcClass.name = [cursor readInt32];
    objcClass.version = [cursor readInt32];
    objcClass.info = [cursor readInt32];
    objcClass.instance_size = [cursor readInt32];
    objcClass.ivars = [cursor readInt32];
    objcClass.methods = [cursor readInt32];
    objcClass.cache = [cursor readInt32];
    objcClass.protocols = [cursor readInt32];

    name = [machOFile stringAtAddress:objcClass.name];
    //NSLog(@"name: %08x", objcClass.name);
    //NSLog(@"name = %@", name);
    if (name == nil) {
        NSLog(@"Note: objcClass.name was %08x, returning nil.", objcClass.name);
        [cursor release];
        return nil;
    }

    aClass = [[[CDOCClass alloc] init] autorelease];
    [aClass setName:name];
    [aClass setSuperClassName:[machOFile stringAtAddress:objcClass.super_class]];
    //NSLog(@"[aClass superClassName]: %@", [aClass superClassName]);

    // Process ivars
    if (objcClass.ivars != 0) {
        uint32_t count, index;
        NSMutableArray *ivars;

        [cursor setOffset:[machOFile dataOffsetForAddress:objcClass.ivars]];
        NSParameterAssert([cursor offset] != 0);

        count = [cursor readInt32];
        ivars = [[NSMutableArray alloc] init];
        for (index = 0; index < count; index++) {
            struct cd_objc_ivar objcIvar;
            NSString *name, *type;

            objcIvar.name = [cursor readInt32];
            objcIvar.type = [cursor readInt32];
            objcIvar.offset = [cursor readInt32];

            name = [machOFile stringAtAddress:objcIvar.name];
            type = [machOFile stringAtAddress:objcIvar.type];

            // bitfields don't need names.
            // NSIconRefBitmapImageRep in AppKit on 10.5 has a single-bit bitfield, plus an unnamed 31-bit field.
            if (type != nil) {
                CDOCIvar *anIvar;

                anIvar = [[CDOCIvar alloc] initWithName:name type:type offset:objcIvar.offset];
                [ivars addObject:anIvar];
                [anIvar release];
            }
        }

        [aClass setIvars:[NSArray arrayWithArray:ivars]];
        [ivars release];
    }

    // Process instance methods
    for (CDOCMethod *method in [self processMethodsAtAddress:objcClass.methods])
        [aClass addInstanceMethod:method];

    // Process meta class
    {
        struct cd_objc_class metaClass;

        NSParameterAssert(objcClass.isa != 0);
        //NSLog(@"meta class, isa = %08x", objcClass.isa);

        [cursor setOffset:[machOFile dataOffsetForAddress:objcClass.isa]];

        metaClass.isa = [cursor readInt32];
        metaClass.super_class = [cursor readInt32];
        metaClass.name = [cursor readInt32];
        metaClass.version = [cursor readInt32];
        metaClass.info = [cursor readInt32];
        metaClass.instance_size = [cursor readInt32];
        metaClass.ivars = [cursor readInt32];
        metaClass.methods = [cursor readInt32];
        metaClass.cache = [cursor readInt32];
        metaClass.protocols = [cursor readInt32];

#if 0
        // TODO (2009-06-23): See if there's anything else interesting here.
        NSLog(@"metaclass= isa:%08x super:%08x  name:%08x ver:%08x  info:%08x isize:%08x  ivar:%08x meth:%08x  cache:%08x proto:%08x",
              metaClass.isa, metaClass.super_class, metaClass.name, metaClass.version, metaClass.info, metaClass.instance_size,
              metaClass.ivars, metaClass.methods, metaClass.cache, metaClass.protocols);
#endif
        // Process class methods
        for (CDOCMethod *method in [self processMethodsAtAddress:metaClass.methods])
            [aClass addClassMethod:method];
    }

    // Process protocols
    for (CDOCProtocol *protocol in [self uniquedProtocolListAtAddress:objcClass.protocols])
        [aClass addProtocol:protocol];

    [cursor release];

    return aClass;
}

// Returns list of uniqued protocols.
- (NSArray *)uniquedProtocolListAtAddress:(uint32_t)address;
{
    NSMutableArray *protocols;

    protocols = [[[NSMutableArray alloc] init] autorelease];;

    if (address != 0) {
        CDDataCursor *cursor;
        struct cd_objc_protocol_list protocolList;
        uint32_t index;

        cursor = [[CDDataCursor alloc] initWithData:[machOFile data]];
        [cursor setByteOrder:[machOFile byteOrder]];
        [cursor setOffset:[machOFile dataOffsetForAddress:address]];

        protocolList.next = [cursor readInt32];
        protocolList.count = [cursor readInt32];

        for (index = 0; index < protocolList.count; index++) {
            uint32_t val;
            CDOCProtocol *protocol, *uniqueProtocol;

            val = [cursor readInt32];
            protocol = [protocolsByAddress objectForKey:[NSNumber numberWithUnsignedInt:val]];
            //NSLog(@"%3d protocol @ %08x: %@", index, val, [protocol name]);
            if (protocol != nil) {
                uniqueProtocol = [protocolsByName objectForKey:[protocol name]];
                if (uniqueProtocol != nil)
                    [protocols addObject:uniqueProtocol];
            }
        }

        [cursor release];
    }

    return protocols;
}

- (NSArray *)processMethodsAtAddress:(uint32_t)address;
{
    return [self processMethodsAtAddress:address isFromProtocolDefinition:NO];
}

- (NSArray *)processMethodsAtAddress:(uint32_t)address isFromProtocolDefinition:(BOOL)isFromProtocolDefinition;
{
    CDDataCursor *cursor;
    NSMutableArray *methods;

    if (address == 0)
        return [NSArray array];

    methods = [NSMutableArray array];

    cursor = [[CDDataCursor alloc] initWithData:[machOFile data]];
    [cursor setByteOrder:[machOFile byteOrder]];
    [cursor setOffset:[machOFile dataOffsetForAddress:address]];
    if ([cursor offset] != 0) {
        struct cd_objc_method_list methodList;
        uint32_t index;

        if (isFromProtocolDefinition)
            methodList._obsolete = 0;
        else
            methodList._obsolete = [cursor readInt32];
        methodList.method_count = [cursor readInt32];

        for (index = 0; index < methodList.method_count; index++) {
            struct cd_objc_method objcMethod;
            NSString *name, *type;

            objcMethod.name = [cursor readInt32];
            objcMethod.types = [cursor readInt32];
            if (isFromProtocolDefinition)
                objcMethod.imp = 0;
            else
                objcMethod.imp = [cursor readInt32];

            name = [machOFile stringAtAddress:objcMethod.name];
            type = [machOFile stringAtAddress:objcMethod.types];
            if (name != nil && type != nil) {
                CDOCMethod *method;

                method = [[CDOCMethod alloc] initWithName:name type:type imp:objcMethod.imp];
                [methods addObject:method];
                [method release];
            } else {
                if (name == nil) NSLog(@"Note: Method name was nil (%08x, %p)", objcMethod.name, name);
                if (type == nil) NSLog(@"Note: Method type was nil (%08x, %p)", objcMethod.types, type);
            }
        }
    }

    [cursor release];

    return [methods reversedArray];
}

- (CDOCCategory *)processCategoryDefinitionAtAddress:(uint32_t)address;
{
    CDOCCategory *aCategory = nil;

    if (address != 0) {
        CDDataCursor *cursor;
        struct cd_objc_category objcCategory;
        NSString *name;

        cursor = [[CDDataCursor alloc] initWithData:[machOFile data]];
        [cursor setByteOrder:[machOFile byteOrder]];
        [cursor setOffset:[machOFile dataOffsetForAddress:address]];

        objcCategory.category_name = [cursor readInt32];
        objcCategory.class_name = [cursor readInt32];
        objcCategory.methods = [cursor readInt32];
        objcCategory.class_methods = [cursor readInt32];
        objcCategory.protocols = [cursor readInt32];

        name = [machOFile stringAtAddress:objcCategory.category_name];
        if (name == nil) {
            NSLog(@"Note: objcCategory.category_name was %08x, returning nil.", objcCategory.category_name);
            [cursor release];
            return nil;
        }

        aCategory = [[[CDOCCategory alloc] init] autorelease];
        [aCategory setName:name];
        [aCategory setClassName:[machOFile stringAtAddress:objcCategory.class_name]];

        for (CDOCMethod *method in [self processMethodsAtAddress:objcCategory.methods])
            [aCategory addInstanceMethod:method];

        for (CDOCMethod *method in [self processMethodsAtAddress:objcCategory.class_methods])
            [aCategory addClassMethod:method];

        for (CDOCProtocol *protocol in [self uniquedProtocolListAtAddress:objcCategory.protocols])
            [aCategory addProtocol:protocol];

        [cursor release];
    }

    return aCategory;
}

- (CDOCProtocol *)protocolAtAddress:(uint32_t)address;
{
    NSNumber *key;
    CDOCProtocol *aProtocol;

    key = [NSNumber numberWithUnsignedInt:address];
    aProtocol = [protocolsByAddress objectForKey:key];
    if (aProtocol == nil) {
        CDDataCursor *cursor;
        uint32_t v1, v2, v3, v4, v5;
        NSString *name;

        //NSLog(@"Creating new protocol from address: 0x%08x", address);
        aProtocol = [[[CDOCProtocol alloc] init] autorelease];
        [protocolsByAddress setObject:aProtocol forKey:key];

        cursor = [[CDDataCursor alloc] initWithData:[machOFile data]];
        [cursor setByteOrder:[machOFile byteOrder]];
        [cursor setOffset:[machOFile dataOffsetForAddress:address]];

        v1 = [cursor readInt32];
        v2 = [cursor readInt32];
        v3 = [cursor readInt32];
        v4 = [cursor readInt32];
        v5 = [cursor readInt32];
        name = [machOFile stringAtAddress:v2];
        [aProtocol setName:name]; // Need to set name before adding to another protocol
        //NSLog(@"data offset for %08x: %08x", v2, [machOFile dataOffsetForAddress:v2]);
        //NSLog(@"[@ %08x] v1-5: 0x%08x 0x%08x 0x%08x 0x%08x 0x%08x (%@)", address, v1, v2, v3, v4, v5, name);

        {
            uint32_t count, index;

            // Protocols
            if (v3 != 0) {
                uint32_t val;

                [cursor setOffset:[machOFile dataOffsetForAddress:v3]];
                val = [cursor readInt32];
                NSParameterAssert(val == 0); // next pointer, let me know if it's ever not zero
                //NSLog(@"val: 0x%08x", val);
                count = [cursor readInt32];
                //NSLog(@"protocol count: %08x", count);
                for (index = 0; index < count; index++) {
                    CDOCProtocol *anotherProtocol;

                    val = [cursor readInt32];
                    //NSLog(@"val[%2d]: 0x%08x", index, val);
                    anotherProtocol = [self protocolAtAddress:val];
                    if (anotherProtocol != nil) {
                        [aProtocol addProtocol:anotherProtocol];
                    } else {
                        NSLog(@"Note: another protocol was nil.");
                    }
                }
            }

            // Instance methods
            for (CDOCMethod *method in [self processMethodsAtAddress:v4 isFromProtocolDefinition:YES])
                [aProtocol addInstanceMethod:method];

            // Class methods
            for (CDOCMethod *method in [self processMethodsAtAddress:v5 isFromProtocolDefinition:YES])
                [aProtocol addClassMethod:method];
        }

        [cursor release];
    } else {
        //NSLog(@"Found existing protocol at address: 0x%08x", address);
    }

    return aProtocol;
}

// Protocols can reference other protocols, so we can't try to create them
// in order.  Instead we create them lazily and just make sure we reference
// all available protocols.

// Many of the protocol structures share the same name, but have differnt method lists.  Create them all, then merge/unique by name after.
// Perhaps a bit more work than necessary, but at least I can see exactly what is happening.
- (void)loadProtocols;
{
    CDLCSegment *objcSegment;
    CDSection *protocolSection;
    uint32_t addr;
    int count, index;

    objcSegment = [machOFile segmentWithName:@"__OBJC"];
    protocolSection = [objcSegment sectionWithName:@"__protocol"];
    addr = [protocolSection addr];

    count = [protocolSection size] / sizeof(struct cd_objc_protocol);
    for (index = 0; index < count; index++, addr += sizeof(struct cd_objc_protocol))
        [self protocolAtAddress:addr]; // Forces them to be loaded

    [self createUniquedProtocols];
}

- (NSData *)objcImageInfoData;
{
    return [[[machOFile segmentWithName:@"__OBJC"] sectionWithName:@"__image_info"] data];
}

@end
