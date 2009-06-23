//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2007  Steve Nygard

#import "CDObjCSegmentProcessor-Private.h"

#import <Foundation/Foundation.h>
#import "CDMachOFile.h"
#import "CDOCCategory.h"
#import "CDOCClass.h"
#import "CDOCIvar.h"
#import "CDOCMethod.h"
#import "CDOCModule.h"
#import "CDOCProtocol.h"
#import "CDOCSymtab.h"
#import "CDSection.h"
#import "CDSegmentCommand.h"
#import "NSArray-Extensions.h"

@implementation CDObjCSegmentProcessor (Private)

- (void)processModules;
{
    CDSegmentCommand *objcSegment;
    CDSection *moduleSection;
    NSData *sectionData;
    CDDataCursor *cursor;

    objcSegment = [machOFile segmentWithName:@"__OBJC"];
    [objcSegment writeSectionData];
    moduleSection = [objcSegment sectionWithName:@"__module_info"];
    sectionData = [moduleSection data];

    cursor = [[CDDataCursor alloc] initWithData:sectionData];
    while ([cursor isAtEnd] == NO) {
        struct cd_objc_module objcModule;
        CDOCModule *module;
        NSString *name;

        objcModule.version = [cursor readLittleInt32];
        objcModule.size = [cursor readLittleInt32];
        objcModule.name = [cursor readLittleInt32];
        objcModule.symtab = [cursor readLittleInt32];

        //NSLog(@"objcModule.size: %u", objcModule.size);
        //NSLog(@"sizeof(struct cd_objc_module): %u", sizeof(struct cd_objc_module));
        assert(objcModule.size == sizeof(struct cd_objc_module)); // Because this is what we're assuming.

        name = [machOFile stringFromVMAddr:objcModule.name];
        if (name != nil && [name length] > 0)
            NSLog(@"Note: a module name is set: %@", name);

        //NSLog(@"%08x %08x %08x %08x - '%@'", objcModule.version, objcModule.size, objcModule.name, objcModule.symtab, name);
        //NSLog(@"\tsect: %@", [[machOFile segmentContainingAddress:objcModule.name] sectionContainingAddress:objcModule.name]);
        //NSLog(@"symtab: %08x", objcModule.symtab);

        module = [[CDOCModule alloc] init];
        [module setVersion:objcModule.version];
        [module setName:[machOFile stringFromVMAddr:objcModule.name]];
        [module setSymtab:[self processSymtabAtAddress:objcModule.symtab]];
        [modules addObject:module];

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
    [cursor setOffset:[machOFile dataOffsetForAddress:address segmentName:@"__OBJC"]];
    //[cursor setOffset:[machOFile dataOffsetForAddress:address]];
    //NSLog(@"cursor offset: %08x", [cursor offset]);
    if ([cursor offset] != 0) {
        objcSymtab.sel_ref_cnt = [cursor readLittleInt32];
        objcSymtab.refs = [cursor readLittleInt32];
        objcSymtab.cls_def_count = [cursor readLittleInt16];
        objcSymtab.cat_def_count = [cursor readLittleInt16];
        //NSLog(@"[@ %08x]: %08x %08x %04x %04x", address, objcSymtab.sel_ref_cnt, objcSymtab.refs, objcSymtab.cls_def_count, objcSymtab.cat_def_count);

        aSymtab = [[[CDOCSymtab alloc] init] autorelease];

        for (index = 0; index < objcSymtab.cls_def_count; index++) {
            CDOCClass *aClass;
            uint32_t val;

            val = [cursor readLittleInt32];
            //NSLog(@"%4d: %08x", index, val);

            aClass = [self processClassDefinitionAtAddress:val];
            if (aClass != nil)
                [aSymtab addClass:aClass];
        }

        for (index = 0; index < objcSymtab.cat_def_count; index++) {
            CDOCCategory *aCategory;
            uint32_t val;

            val = [cursor readLittleInt32];
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
    [cursor setOffset:[machOFile dataOffsetForAddress:address]];

    objcClass.isa = [cursor readLittleInt32];
    objcClass.super_class = [cursor readLittleInt32];
    objcClass.name = [cursor readLittleInt32];
    objcClass.version = [cursor readLittleInt32];
    objcClass.info = [cursor readLittleInt32];
    objcClass.instance_size = [cursor readLittleInt32];
    objcClass.ivars = [cursor readLittleInt32];
    objcClass.methods = [cursor readLittleInt32];
    objcClass.cache = [cursor readLittleInt32];
    objcClass.protocols = [cursor readLittleInt32];

    name = [machOFile stringFromVMAddr:objcClass.name];
    //NSLog(@"name: %08x", objcClass.name);
    //NSLog(@"name = %@", name);
    if (name == nil) {
        NSLog(@"Note: objcClass.name was %08x, returning nil.", objcClass.name);
        [cursor release];
        return nil;
    }

    aClass = [[[CDOCClass alloc] init] autorelease];
    [aClass setName:name];
    [aClass setSuperClassName:[machOFile stringFromVMAddr:objcClass.super_class]];
    //NSLog(@"[aClass superClassName]: %@", [aClass superClassName]);

    // Process ivars
    if (objcClass.ivars != 0) {
        uint32_t count, index;
        NSMutableArray *ivars;

        [cursor setOffset:[machOFile dataOffsetForAddress:objcClass.ivars]];
        NSParameterAssert([cursor offset] != 0);

        count = [cursor readLittleInt32];
        ivars = [[NSMutableArray alloc] init];
        for (index = 0; index < count; index++) {
            struct cd_objc_ivar objcIvar;
            NSString *name, *type;

            objcIvar.name = [cursor readLittleInt32];
            objcIvar.type = [cursor readLittleInt32];
            objcIvar.offset = [cursor readLittleInt32];

            name = [machOFile stringFromVMAddr:objcIvar.name];
            type = [machOFile stringFromVMAddr:objcIvar.type];

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

        metaClass.isa = [cursor readLittleInt32];
        metaClass.super_class = [cursor readLittleInt32];
        metaClass.name = [cursor readLittleInt32];
        metaClass.version = [cursor readLittleInt32];
        metaClass.info = [cursor readLittleInt32];
        metaClass.instance_size = [cursor readLittleInt32];
        metaClass.ivars = [cursor readLittleInt32];
        metaClass.methods = [cursor readLittleInt32];
        metaClass.cache = [cursor readLittleInt32];
        metaClass.protocols = [cursor readLittleInt32];

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
    [aClass addProtocolsFromArray:[self uniquedProtocolListAtAddress:objcClass.protocols]];

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
        [cursor setOffset:[machOFile dataOffsetForAddress:address]];

        protocolList.next = [cursor readLittleInt32];
        protocolList.count = [cursor readLittleInt32];

        for (index = 0; index < protocolList.count; index++) {
            uint32_t val;
            CDOCProtocol *protocol, *uniqueProtocol;

            val = [cursor readLittleInt32];
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
    CDDataCursor *cursor;
    NSMutableArray *methods;

    if (address == 0)
        return [NSArray array];

    methods = [NSMutableArray array];

    cursor = [[CDDataCursor alloc] initWithData:[machOFile data]];
    [cursor setOffset:[machOFile dataOffsetForAddress:address]];
    if ([cursor offset] != 0) {
        struct cd_objc_method_list methodList;
        uint32_t index;

        methodList._obsolete = [cursor readLittleInt32];
        methodList.method_count = [cursor readLittleInt32];

        for (index = 0; index < methodList.method_count; index++) {
            struct cd_objc_method objcMethod;
            NSString *name, *type;

            objcMethod.name = [cursor readLittleInt32];
            objcMethod.types = [cursor readLittleInt32];
            objcMethod.imp = [cursor readLittleInt32];

            name = [machOFile stringFromVMAddr:objcMethod.name];
            type = [machOFile stringFromVMAddr:objcMethod.types];
            if (name != nil && type != nil) {
                CDOCMethod *method;

                method = [[CDOCMethod alloc] initWithName:name type:type imp:objcMethod.imp];
                [methods addObject:method];
                [method release];
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
        [cursor setOffset:[machOFile dataOffsetForAddress:address]];

        objcCategory.category_name = [cursor readLittleInt32];
        objcCategory.class_name = [cursor readLittleInt32];
        objcCategory.methods = [cursor readLittleInt32];
        objcCategory.class_methods = [cursor readLittleInt32];
        objcCategory.protocols = [cursor readLittleInt32];

        name = [machOFile stringFromVMAddr:objcCategory.category_name];
        if (name == nil) {
            NSLog(@"Note: objcCategory.category_name was %08x, returning nil.", objcCategory.category_name);
            [cursor release];
            return nil;
        }

        aCategory = [[[CDOCCategory alloc] init] autorelease];
        [aCategory setName:name];
        [aCategory setClassName:[machOFile stringFromVMAddr:objcCategory.class_name]];

        for (CDOCMethod *method in [self processMethodsAtAddress:objcCategory.methods])
            [aCategory addInstanceMethod:method];

        for (CDOCMethod *method in [self processMethodsAtAddress:objcCategory.class_methods])
            [aCategory addClassMethod:method];

        [aCategory addProtocolsFromArray:[self uniquedProtocolListAtAddress:objcCategory.protocols]];

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
        [cursor setOffset:[machOFile dataOffsetForAddress:address]];

        v1 = [cursor readLittleInt32];
        v2 = [cursor readLittleInt32];
        v3 = [cursor readLittleInt32];
        v4 = [cursor readLittleInt32];
        v5 = [cursor readLittleInt32];
        name = [machOFile stringFromVMAddr:v2];
        [aProtocol setName:name]; // Need to set name before adding to another protocol
        //NSLog(@"data offset for %08x: %08x", v2, [machOFile dataOffsetForAddress:v2]);
        //NSLog(@"[@ %08x] v1-5: 0x%08x 0x%08x 0x%08x 0x%08x 0x%08x (%@)", address, v1, v2, v3, v4, v5, name);

        {
            uint32_t count, index;

            // Protocols
            if (v3 != 0) {
                uint32_t val;

                [cursor setOffset:[machOFile dataOffsetForAddress:v3]];
                val = [cursor readLittleInt32];
                NSParameterAssert(val == 0); // next pointer, let me know if it's ever not zero
                //NSLog(@"val: 0x%08x", val);
                count = [cursor readLittleInt32];
                //NSLog(@"protocol count: %08x", count);
                for (index = 0; index < count; index++) {
                    CDOCProtocol *anotherProtocol;

                    val = [cursor readLittleInt32];
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
            if (v4 != 0) {
                [cursor setOffset:[machOFile dataOffsetForAddress:v4]];
                count = [cursor readLittleInt32];
                //NSLog(@"instance method count: %08x", count);

                for (index = 0; index < count; index++) {
                    NSString *name, *type;

                    name = [machOFile stringFromVMAddr:[cursor readLittleInt32]];
                    type = [machOFile stringFromVMAddr:[cursor readLittleInt32]];
                    //NSLog(@"name: %@", name);
                    //NSLog(@"type: %@", type);
                    if (name != nil && type != nil) {
                        CDOCMethod *method;

                        method = [[CDOCMethod alloc] initWithName:name type:type];
                        [aProtocol addInstanceMethod:method];
                        [method release];
                    } else {
                        NSLog(@"Note: name or type is nil.");
                    }
                }
            }

            // Class methods
            if (v5 != 0) {
                [cursor setOffset:[machOFile dataOffsetForAddress:v5]];
                count = [cursor readLittleInt32];
                //NSLog(@"class method count: %08x", count);

                for (index = 0; index < count; index++) {
                    NSString *name, *type;

                    name = [machOFile stringFromVMAddr:[cursor readLittleInt32]];
                    type = [machOFile stringFromVMAddr:[cursor readLittleInt32]];
                    //NSLog(@"name: %@", name);
                    //NSLog(@"type: %@", type);
                    if (name != nil && type != nil) {
                        CDOCMethod *method;

                        method = [[CDOCMethod alloc] initWithName:name type:type];
                        [aProtocol addClassMethod:method];
                        [method release];
                    } else {
                        NSLog(@"Note: name or type is nil.");
                    }
                }
            }
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
- (void)processProtocolSection;
{
    CDSegmentCommand *objcSegment;
    CDSection *protocolSection;
    uint32_t addr;
    int count, index;

    objcSegment = [machOFile segmentWithName:@"__OBJC"];
    protocolSection = [objcSegment sectionWithName:@"__protocol"];
    addr = [protocolSection addr];

    count = [protocolSection size] / sizeof(struct cd_objc_protocol);
    for (index = 0; index < count; index++, addr += sizeof(struct cd_objc_protocol))
        [self protocolAtAddress:addr]; // Forces them to be loaded

    // Now unique the protocols by name and store in protocolsByName

    for (NSNumber *key in [[protocolsByAddress allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        CDOCProtocol *p1, *p2;

        p1 = [protocolsByAddress objectForKey:key];
        p2 = [protocolsByName objectForKey:[p1 name]];
        if (p2 == nil) {
            p2 = [[CDOCProtocol alloc] init];
            [p2 setName:[p1 name]];
            [protocolsByName setObject:p2 forKey:[p2 name]];
            // adopted protocols still not set, will want uniqued instances
            [p2 release];
        } else {
        }
    }

    //NSLog(@"uniqued protocol names: %@", [[[protocolsByName allKeys] sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@", "]);

    // And finally fill in adopted protocols, instance and class methods
    for (NSNumber *key in [[protocolsByAddress allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        CDOCProtocol *p1, *uniqueProtocol;

        p1 = [protocolsByAddress objectForKey:key];
        uniqueProtocol = [protocolsByName objectForKey:[p1 name]];
        for (CDOCProtocol *p2 in [p1 protocols])
            [uniqueProtocol addProtocol:[protocolsByName objectForKey:[p2 name]]];

        if ([[uniqueProtocol classMethods] count] == 0) {
            for (CDOCMethod *method in [p1 classMethods])
                [uniqueProtocol addClassMethod:method];
        } else {
            NSParameterAssert([[uniqueProtocol classMethods] count] == [[p1 classMethods] count]);
        }

        if ([[uniqueProtocol instanceMethods] count] == 0) {
            for (CDOCMethod *method in [p1 instanceMethods])
                [uniqueProtocol addInstanceMethod:method];
        } else {
            NSParameterAssert([[uniqueProtocol instanceMethods] count] == [[p1 instanceMethods] count]);
        }
    }

    //NSLog(@"protocolsByName: %@", protocolsByName);
}

- (void)checkUnreferencedProtocols;
{
    NSLog(@" > %s", _cmd);
    NSLog(@"<  %s", _cmd);
}

@end
