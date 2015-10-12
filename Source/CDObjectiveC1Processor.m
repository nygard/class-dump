// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDObjectiveC1Processor.h"

#include <mach-o/arch.h>

#import "CDClassDump.h"
#import "CDLCDylib.h"
#import "CDMachOFile.h"
#import "CDOCCategory.h"
#import "CDOCClass.h"
#import "CDOCInstanceVariable.h"
#import "CDOCMethod.h"
#import "CDOCModule.h"
#import "CDOCProtocol.h"
#import "CDOCSymtab.h"
#import "CDVisitor.h"
#import "CDProtocolUniquer.h"
#import "CDOCClassReference.h"

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
{
    NSMutableArray *_modules;
}

- (id)initWithMachOFile:(CDMachOFile *)machOFile;
{
    if ((self = [super initWithMachOFile:machOFile])) {
        _modules = [[NSMutableArray alloc] init];
    }

    return self;
}

#pragma mark -

- (void)process;
{
    if ([self.machOFile isEncrypted] == NO && [self.machOFile canDecryptAllSegments]) {
        [super process];

        [self processModules];
    }
}

#pragma mark - Formerly private

- (void)processModules;
{
    CDSection *moduleSection = [[self.machOFile segmentWithName:@"__OBJC"] sectionWithName:@"__module_info"];

    CDMachOFileDataCursor *cursor = [[CDMachOFileDataCursor alloc] initWithSection:moduleSection];
    while ([cursor isAtEnd] == NO) {
        struct cd_objc_module objcModule;

        objcModule.version = [cursor readInt32];
        objcModule.size    = [cursor readInt32];
        objcModule.name    = [cursor readInt32];
        objcModule.symtab  = [cursor readInt32];

        //NSLog(@"objcModule.size: %u", objcModule.size);
        //NSLog(@"sizeof(struct cd_objc_module): %u", sizeof(struct cd_objc_module));
        assert(objcModule.size == sizeof(struct cd_objc_module)); // Because this is what we're assuming.

        NSString *name = [self.machOFile stringAtAddress:objcModule.name];
        if (name != nil && [name length] > 0 && debug)
            NSLog(@"Note: a module name is set: %@", name);

        //NSLog(@"%08x %08x %08x %08x - '%@'", objcModule.version, objcModule.size, objcModule.name, objcModule.symtab, name);
        //NSLog(@"\tsect: %@", [[machOFile segmentContainingAddress:objcModule.name] sectionContainingAddress:objcModule.name]);
        //NSLog(@"symtab: %08x", objcModule.symtab);

        CDOCModule *module = [[CDOCModule alloc] init];
        module.version = objcModule.version;
        module.name    = [self.machOFile stringAtAddress:objcModule.name];
        module.symtab  = [self processSymtabAtAddress:objcModule.symtab];
        [_modules addObject:module];

        [self addClassesFromArray:[[module symtab] classes]];
        [self addCategoriesFromArray:[[module symtab] categories]];
    }
}

- (CDOCSymtab *)processSymtabAtAddress:(uint32_t)address;
{
    CDLCSegment *segment = [self.machOFile segmentContainingAddress:address];
    CDSection *section = [segment sectionContainingAddress:address];
    if (![[section segmentName] isEqualToString:@"__OBJC"])
        return nil; // This can happen with the symtab in a module. In one case, the symtab is in __DATA, __bss, in the zero filled area.

    CDMachOFileDataCursor *cursor = [[CDMachOFileDataCursor alloc] initWithFile:self.machOFile address:address];

    struct cd_objc_symtab objcSymtab;
    objcSymtab.sel_ref_cnt   = [cursor readInt32];
    objcSymtab.refs          = [cursor readInt32];
    objcSymtab.cls_def_count = [cursor readInt16];
    objcSymtab.cat_def_count = [cursor readInt16];
    //NSLog(@"[@ %08x]: %08x %08x %04x %04x", address, objcSymtab.sel_ref_cnt, objcSymtab.refs, objcSymtab.cls_def_count, objcSymtab.cat_def_count);

    CDOCSymtab *symtab = [[CDOCSymtab alloc] init];
    
    for (unsigned int index = 0; index < objcSymtab.cls_def_count; index++) {
        uint32_t val = [cursor readInt32];
        //NSLog(@"%4d: %08x", index, val);

        CDOCClass *aClass = [self processClassDefinitionAtAddress:val];
        if (aClass != nil)
            [symtab addClass:aClass];
    }

    for (unsigned int index = 0; index < objcSymtab.cat_def_count; index++) {
        uint32_t val = [cursor readInt32];
        //NSLog(@"%4d: %08x", index, val);

        CDOCCategory *category = [self processCategoryDefinitionAtAddress:val];
        if (category != nil)
            [symtab addCategory:category];
    }

    return symtab;
}

- (CDOCClass *)processClassDefinitionAtAddress:(uint32_t)address;
{
    CDMachOFileDataCursor *cursor = [[CDMachOFileDataCursor alloc] initWithFile:self.machOFile address:address];

    struct cd_objc_class objcClass;

    objcClass.isa           = [cursor readInt32];
    objcClass.super_class   = [cursor readInt32];
    objcClass.name          = [cursor readInt32];
    objcClass.version       = [cursor readInt32];
    objcClass.info          = [cursor readInt32];
    objcClass.instance_size = [cursor readInt32];
    objcClass.ivars         = [cursor readInt32];
    objcClass.methods       = [cursor readInt32];
    objcClass.cache         = [cursor readInt32];
    objcClass.protocols     = [cursor readInt32];

    NSString *className = [self.machOFile stringAtAddress:objcClass.name];
    //NSLog(@"name: %08x", objcClass.name);
    //NSLog(@"className = %@", className);
    if (className == nil) {
        NSLog(@"Note: objcClass.name was %08x, returning nil.", objcClass.name);
        return nil;
    }

    CDOCClass *aClass = [[CDOCClass alloc] init];
    aClass.name           = className;
    
    // TODO: can we extract more than just the string from here?
    aClass.superClassRef  = [[CDOCClassReference alloc] initWithClassName:[self.machOFile stringAtAddress:objcClass.super_class]];

    // Process ivars
    if (objcClass.ivars != 0) {
        [cursor setAddress:objcClass.ivars];
        NSParameterAssert([cursor offset] != 0);

        uint32_t count = [cursor readInt32];
        NSMutableArray *instanceVariables = [[NSMutableArray alloc] init];
        for (uint32_t index = 0; index < count; index++) {
            struct cd_objc_ivar objcIvar;

            objcIvar.name   = [cursor readInt32];
            objcIvar.type   = [cursor readInt32];
            objcIvar.offset = [cursor readInt32];

            NSString *name       = [self.machOFile stringAtAddress:objcIvar.name];
            NSString *typeString = [self.machOFile stringAtAddress:objcIvar.type];

            // bitfields don't need names.
            // NSIconRefBitmapImageRep in AppKit on 10.5 has a single-bit bitfield, plus an unnamed 31-bit field.
            if (typeString != nil) {
                CDOCInstanceVariable *instanceVariable = [[CDOCInstanceVariable alloc] initWithName:name typeString:typeString offset:objcIvar.offset];
                [instanceVariables addObject:instanceVariable];
            }
        }

        aClass.instanceVariables = [NSArray arrayWithArray:instanceVariables];
    }

    // Process instance methods
    for (CDOCMethod *method in [self processMethodsAtAddress:objcClass.methods])
        [aClass addInstanceMethod:method];

    // Process meta class
    {
        NSParameterAssert(objcClass.isa != 0);
        //NSLog(@"meta class, isa = %08x", objcClass.isa);

        [cursor setAddress:objcClass.isa];

        struct cd_objc_class metaClass;
        
        metaClass.isa           = [cursor readInt32];
        metaClass.super_class   = [cursor readInt32];
        metaClass.name          = [cursor readInt32];
        metaClass.version       = [cursor readInt32];
        metaClass.info          = [cursor readInt32];
        metaClass.instance_size = [cursor readInt32];
        metaClass.ivars         = [cursor readInt32];
        metaClass.methods       = [cursor readInt32];
        metaClass.cache         = [cursor readInt32];
        metaClass.protocols     = [cursor readInt32];

#if 0
        // TODO: (2009-06-23) See if there's anything else interesting here.
        NSLog(@"metaclass= isa:%08x super:%08x  name:%08x ver:%08x  info:%08x isize:%08x  ivar:%08x meth:%08x  cache:%08x proto:%08x",
              metaClass.isa, metaClass.super_class, metaClass.name, metaClass.version, metaClass.info, metaClass.instance_size,
              metaClass.ivars, metaClass.methods, metaClass.cache, metaClass.protocols);
#endif
        // Process class methods
        for (CDOCMethod *method in [self processMethodsAtAddress:metaClass.methods])
            [aClass addClassMethod:method];
    }

    // Process protocols
    for (CDOCProtocol *protocol in [self.protocolUniquer uniqueProtocolsAtAddresses:[self protocolAddressListAtAddress:objcClass.protocols]])
        [aClass addProtocol:protocol];

    return aClass;
}

// Returns list of NSNumber containing the protocol addresses
- (NSArray *)protocolAddressListAtAddress:(uint64_t)address;
{
    NSMutableArray *addresses = [[NSMutableArray alloc] init];;
    
    if (address != 0) {
        CDMachOFileDataCursor *cursor = [[CDMachOFileDataCursor alloc] initWithFile:self.machOFile address:address];
        
        struct cd_objc_protocol_list protocolList;
        protocolList.next  = [cursor readInt32];
        protocolList.count = [cursor readInt32];
        
        for (uint32_t index = 0; index < protocolList.count; index++) {
            uint32_t val = [cursor readInt32];
            [addresses addObject:[NSNumber numberWithUnsignedLongLong:val]];
        }
    }
    
    return [addresses copy];
}

- (NSArray *)processMethodsAtAddress:(uint32_t)address;
{
    return [self processMethodsAtAddress:address isFromProtocolDefinition:NO];
}

- (NSArray *)processMethodsAtAddress:(uint32_t)address isFromProtocolDefinition:(BOOL)isFromProtocolDefinition;
{
    if (address == 0)
        return @[];

    NSMutableArray *methods = [NSMutableArray array];

    CDMachOFileDataCursor *cursor = [[CDMachOFileDataCursor alloc] initWithFile:self.machOFile address:address];
    if ([cursor offset] != 0) {
        struct cd_objc_method_list methodList;

        if (isFromProtocolDefinition)
            methodList._obsolete = 0;
        else
            methodList._obsolete = [cursor readInt32];
        methodList.method_count = [cursor readInt32];

        for (uint32_t index = 0; index < methodList.method_count; index++) {
            struct cd_objc_method objcMethod;

            objcMethod.name  = [cursor readInt32];
            objcMethod.types = [cursor readInt32];
            if (isFromProtocolDefinition)
                objcMethod.imp = 0;
            else
                objcMethod.imp = [cursor readInt32];

            NSString *name = [self.machOFile stringAtAddress:objcMethod.name];
            NSString *type = [self.machOFile stringAtAddress:objcMethod.types];
            if (name != nil && type != nil) {
                CDOCMethod *method = [[CDOCMethod alloc] initWithName:name typeString:type address:objcMethod.imp];
                [methods addObject:method];
            } else {
                if (name == nil) NSLog(@"Note: Method name was nil (%08x, %p)", objcMethod.name, name);
                if (type == nil) NSLog(@"Note: Method type was nil (%08x, %p)", objcMethod.types, type);
            }
        }
    }

    return [methods reversedArray];
}

- (CDOCCategory *)processCategoryDefinitionAtAddress:(uint32_t)address;
{
    CDOCCategory *category = nil;

    if (address != 0) {
        CDMachOFileDataCursor *cursor = [[CDMachOFileDataCursor alloc] initWithFile:self.machOFile address:address];

        struct cd_objc_category objcCategory;
        objcCategory.category_name = [cursor readInt32];
        objcCategory.class_name    = [cursor readInt32];
        objcCategory.methods       = [cursor readInt32];
        objcCategory.class_methods = [cursor readInt32];
        objcCategory.protocols     = [cursor readInt32];

        NSString *name = [self.machOFile stringAtAddress:objcCategory.category_name];
        if (name == nil) {
            NSLog(@"Note: objcCategory.category_name was %08x, returning nil.", objcCategory.category_name);
            return nil;
        }

        category = [[CDOCCategory alloc] init];
        category.name = name;
        
        // TODO: can we extract more than just the string from here?
        category.classRef = [[CDOCClassReference alloc] initWithClassName:[self.machOFile stringAtAddress:objcCategory.class_name]];

        for (CDOCMethod *method in [self processMethodsAtAddress:objcCategory.methods])
            [category addInstanceMethod:method];

        for (CDOCMethod *method in [self processMethodsAtAddress:objcCategory.class_methods])
            [category addClassMethod:method];

        for (CDOCProtocol *protocol in [self.protocolUniquer uniqueProtocolsAtAddresses:[self protocolAddressListAtAddress:objcCategory.protocols]])
            [category addProtocol:protocol];
    }

    return category;
}

- (CDOCProtocol *)protocolAtAddress:(uint32_t)address;
{
    CDOCProtocol *protocol = [self.protocolUniquer protocolWithAddress:address];
    if (protocol == nil) {
        //NSLog(@"Creating new protocol from address: 0x%08x", address);
        protocol = [[CDOCProtocol alloc] init];
        [self.protocolUniquer setProtocol:protocol withAddress:address];

        CDMachOFileDataCursor *cursor = [[CDMachOFileDataCursor alloc] initWithFile:self.machOFile address:address];

        /*uint32_t v1 =*/ [cursor readInt32];
        uint32_t v2 = [cursor readInt32];
        uint32_t v3 = [cursor readInt32];
        uint32_t v4 = [cursor readInt32];
        uint32_t v5 = [cursor readInt32];
        NSString *name = [self.machOFile stringAtAddress:v2];
        protocol.name = name; // Need to set name before adding to another protocol
        //NSLog(@"data offset for %08x: %08x", v2, [machOFile dataOffsetForAddress:v2]);
        //NSLog(@"[@ %08x] v1-5: 0x%08x 0x%08x 0x%08x 0x%08x 0x%08x (%@)", address, v1, v2, v3, v4, v5, name);

        {
            // Protocols
            if (v3 != 0) {
                [cursor setAddress:v3];
                uint32_t val = [cursor readInt32];
                NSParameterAssert(val == 0); // next pointer, let me know if it's ever not zero
                //NSLog(@"val: 0x%08x", val);
                uint32_t count = [cursor readInt32];
                //NSLog(@"protocol count: %08x", count);
                for (uint32_t index = 0; index < count; index++) {
                    val = [cursor readInt32];
                    //NSLog(@"val[%2d]: 0x%08x", index, val);
                    CDOCProtocol *anotherProtocol = [self protocolAtAddress:val];
                    if (anotherProtocol != nil) {
                        [protocol addProtocol:anotherProtocol];
                    } else {
                        NSLog(@"Note: another protocol was nil.");
                    }
                }
            }

            // Instance methods
            for (CDOCMethod *method in [self processMethodsAtAddress:v4 isFromProtocolDefinition:YES])
                [protocol addInstanceMethod:method];

            // Class methods
            for (CDOCMethod *method in [self processMethodsAtAddress:v5 isFromProtocolDefinition:YES])
                [protocol addClassMethod:method];
        }
    } else {
        //NSLog(@"Found existing protocol at address: 0x%08x", address);
    }

    return protocol;
}

// Protocols can reference other protocols, so we can't try to create them
// in order.  Instead we create them lazily and just make sure we reference
// all available protocols.

// Many of the protocol structures share the same name, but have differnt method lists.  Create them all, then merge/unique by name after.
// Perhaps a bit more work than necessary, but at least I can see exactly what is happening.
- (void)loadProtocols;
{
    CDSection *protocolSection = [[self.machOFile segmentWithName:@"__OBJC"] sectionWithName:@"__protocol"];
    uint32_t addr = (uint32_t)[protocolSection addr];

    NSUInteger count = [protocolSection size] / sizeof(struct cd_objc_protocol);
    for (NSUInteger index = 0; index < count; index++, addr += (uint32_t)sizeof(struct cd_objc_protocol))
        [self protocolAtAddress:addr]; // Forces them to be loaded
}

- (CDSection *)objcImageInfoSection;
{
    return [[self.machOFile segmentWithName:@"__OBJC"] sectionWithName:@"__image_info"];
}

@end
