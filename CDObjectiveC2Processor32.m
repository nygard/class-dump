//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2009 Steve Nygard.  All rights reserved.

#import "CDObjectiveC2Processor32.h"

#import "CDMachOFile.h"
#import "CDSection.h"
#import "CDLCSegment.h"
#import "CDDataCursor.h"
#import "CDOCClass.h"
#import "CDOCMethod.h"
#import "CDVisitor.h"
#import "CDOCIvar.h"
#import "NSArray-Extensions.h"
#import "CDLCDynamicSymbolTable.h"
#import "CDLCSymbolTable.h"
#import "CDOCCategory.h"
#import "CDClassDump.h"
#import "CDRelocationInfo.h"
#import "CDSymbol.h"
#import "CDOCProperty.h"
#import "cd_objc2.h"

@implementation CDObjectiveC2Processor32

- (void)loadProtocols;
{
    CDLCSegment *segment;
    CDSection *section;
    NSData *sectionData;
    CDDataCursor *cursor;

    segment = [machOFile segmentWithName:@"__DATA"];
    section = [segment sectionWithName:@"__objc_protolist"];
    sectionData = [section data];

    cursor = [[CDDataCursor alloc] initWithData:sectionData];
    while ([cursor isAtEnd] == NO)
        [self protocolAtAddress:[cursor readInt32]];
    [cursor release];

    [self createUniquedProtocols];
}

- (void)loadClasses;
{
    CDLCSegment *segment;
    CDSection *section;
    NSData *sectionData;
    CDDataCursor *cursor;

    segment = [machOFile segmentWithName:@"__DATA"];
    section = [segment sectionWithName:@"__objc_classlist"];
    sectionData = [section data];
    [sectionData writeToFile:@"/tmp/classes.dat" atomically:NO];

    cursor = [[CDDataCursor alloc] initWithData:sectionData];
    while ([cursor isAtEnd] == NO) {
        uint32_t val;
        CDOCClass *aClass;

        //NSLog(@"----------------------------------------------------------------------");
        val = [cursor readInt32];
        //NSLog(@"class @ %08x", val);
        aClass = [self loadClassAtAddress:val];
        if (aClass != nil) {
            [classes addObject:aClass];
            [classesByAddress setObject:aClass forKey:[NSNumber numberWithUnsignedInteger:val]];
        }
    }
    [cursor release];
}

- (void)loadCategories;
{
    CDLCSegment *segment;
    CDSection *section;
    NSData *sectionData;
    CDDataCursor *cursor;

    segment = [machOFile segmentWithName:@"__DATA"];
    section = [segment sectionWithName:@"__objc_catlist"];
    sectionData = [section data];

    cursor = [[CDDataCursor alloc] initWithData:sectionData];
    while ([cursor isAtEnd] == NO) {
        CDOCCategory *category;

        category = [self loadCategoryAtAddress:[cursor readInt32]];
        if (category != nil)
            [categories addObject:category];
    }
}

- (CDOCProtocol *)protocolAtAddress:(uint32_t)address;
{
    NSNumber *key;
    CDOCProtocol *protocol;

    if (address == 0)
        return nil;

    key = [NSNumber numberWithUnsignedInteger:address];
    protocol = [protocolsByAddress objectForKey:key];
    if (protocol == nil) {
        struct cd_objc2_protocol_32 objc2Protocol;
        CDDataCursor *cursor;
        NSString *str;

        protocol = [[[CDOCProtocol alloc] init] autorelease];
        [protocolsByAddress setObject:protocol forKey:key];

        cursor = [[CDDataCursor alloc] initWithData:[machOFile data]];
        [cursor setByteOrder:[machOFile byteOrder]];
        [cursor setOffset:[machOFile dataOffsetForAddress:address]];
        NSParameterAssert([cursor offset] != 0);

        objc2Protocol.isa = [cursor readInt32];
        objc2Protocol.name = [cursor readInt32];
        objc2Protocol.protocols = [cursor readInt32];
        objc2Protocol.instanceMethods = [cursor readInt32];
        objc2Protocol.classMethods = [cursor readInt32];
        objc2Protocol.optionalInstanceMethods = [cursor readInt32];
        objc2Protocol.optionalClassMethods = [cursor readInt32];
        objc2Protocol.instanceProperties = [cursor readInt32];

        //NSLog(@"----------------------------------------");
        //NSLog(@"%08lx %08lx %08lx %08lx", objc2Protocol.isa, objc2Protocol.name, objc2Protocol.protocols, objc2Protocol.instanceMethods);
        //NSLog(@"%08lx %08lx %08lx %08lx", objc2Protocol.classMethods, objc2Protocol.optionalInstanceMethods, objc2Protocol.optionalClassMethods, objc2Protocol.instanceProperties);

        str = [machOFile stringAtAddress:objc2Protocol.name];
        [protocol setName:str];

        if (objc2Protocol.protocols != 0) {
            uint32_t count, index;

            [cursor setOffset:[machOFile dataOffsetForAddress:objc2Protocol.protocols]];
            count = [cursor readInt32];
            for (index = 0; index < count; index++) {
                uint32_t val;
                CDOCProtocol *anotherProtocol;

                val = [cursor readInt32];
                anotherProtocol = [self protocolAtAddress:val];
                if (anotherProtocol != nil) {
                    [protocol addProtocol:anotherProtocol];
                } else {
                    NSLog(@"Note: another protocol was nil.");
                }
            }
        }

        for (CDOCMethod *method in [self loadMethodsAtAddress:objc2Protocol.instanceMethods])
            [protocol addInstanceMethod:method];

        for (CDOCMethod *method in [self loadMethodsAtAddress:objc2Protocol.classMethods])
            [protocol addClassMethod:method];

        for (CDOCMethod *method in [self loadMethodsAtAddress:objc2Protocol.optionalInstanceMethods])
            [protocol addOptionalInstanceMethod:method];

        for (CDOCMethod *method in [self loadMethodsAtAddress:objc2Protocol.optionalClassMethods])
            [protocol addOptionalClassMethod:method];

        [cursor release];
    }

    return protocol;
}

- (CDOCCategory *)loadCategoryAtAddress:(uint32_t)address;
{
    struct cd_objc2_category_32 objc2Category;
    CDDataCursor *cursor;
    NSString *str;
    CDOCCategory *category;

    if (address == 0)
        return nil;

    cursor = [[CDDataCursor alloc] initWithData:[machOFile data]];
    [cursor setByteOrder:[machOFile byteOrder]];
    [cursor setOffset:[machOFile dataOffsetForAddress:address]];
    NSParameterAssert([cursor offset] != 0);

    objc2Category.name = [cursor readInt32];
    objc2Category.class = [cursor readInt32];
    objc2Category.instanceMethods = [cursor readInt32];
    objc2Category.classMethods = [cursor readInt32];
    objc2Category.v5 = [cursor readInt32];
    objc2Category.v6 = [cursor readInt32];
    objc2Category.v7 = [cursor readInt32];
    objc2Category.v8 = [cursor readInt32];
    //NSLog(@"----------------------------------------");
    //NSLog(@"%08lx %08lx %08lx %08lx", objc2Category.name, objc2Category.class, objc2Category.instanceMethods, objc2Category.classMethods);
    //NSLog(@"%08lx %08lx %08lx %08lx", objc2Category.v5, objc2Category.v6, objc2Category.v7, objc2Category.v8);

    category = [[[CDOCCategory alloc] init] autorelease];
    str = [machOFile stringAtAddress:objc2Category.name];
    [category setName:str];

    for (CDOCMethod *method in [self loadMethodsAtAddress:objc2Category.instanceMethods])
        [category addInstanceMethod:method];

    for (CDOCMethod *method in [self loadMethodsAtAddress:objc2Category.classMethods])
        [category addClassMethod:method];

    if (objc2Category.class == 0) {
        [category setClassName:[machOFile externalClassNameForAddress:address + sizeof(objc2Category.name)]];
    } else {
        if ([machOFile hasRelocationEntryForAddress:address + sizeof(objc2Category.name)]) {
            [category setClassName:[machOFile externalClassNameForAddress:address + sizeof(objc2Category.name)]];
            NSLog(@"got external class name (%@) for category.", [category className]);
        } else {
            CDOCClass *aClass;

            aClass = [classesByAddress objectForKey:[NSNumber numberWithUnsignedInteger:objc2Category.class]];
            [category setClassName:[aClass name]];
        }
    }

    [cursor release];

    return category;
}

- (CDOCClass *)loadClassAtAddress:(uint32_t)address;
{
    struct cd_objc2_class_32 objc2Class;
    struct cd_objc2_class_ro_t_32 objc2ClassData;
    CDDataCursor *cursor;
    NSString *str;
    CDOCClass *aClass;

    if (address == 0)
        return nil;

    //NSLog(@"%s, address=%08lx", _cmd, address);

    cursor = [[CDDataCursor alloc] initWithData:[machOFile data]];
    [cursor setByteOrder:[machOFile byteOrder]];
    [cursor setOffset:[machOFile dataOffsetForAddress:address]];
    NSParameterAssert([cursor offset] != 0);

    objc2Class.isa = [cursor readInt32];
    objc2Class.superclass = [cursor readInt32];
    objc2Class.cache = [cursor readInt32];
    objc2Class.vtable = [cursor readInt32];
    objc2Class.data = [cursor readInt32];
    objc2Class.reserved1 = [cursor readInt32];
    objc2Class.reserved2 = [cursor readInt32];
    objc2Class.reserved3 = [cursor readInt32];
    //NSLog(@"objc2Class 32");
    //NSLog(@"%08lx %08lx %08lx %08lx", objc2Class.isa, objc2Class.superclass, objc2Class.cache, objc2Class.vtable);
    //NSLog(@"%08lx %08lx %08lx %08lx", objc2Class.data, objc2Class.reserved1, objc2Class.reserved2, objc2Class.reserved3);

    NSParameterAssert(objc2Class.data != 0);
    [cursor setOffset:[machOFile dataOffsetForAddress:objc2Class.data]];
    objc2ClassData.flags = [cursor readInt32];
    objc2ClassData.instanceStart = [cursor readInt32];
    objc2ClassData.instanceSize = [cursor readInt32];
    //objc2ClassData.reserved = [cursor readInt32];
    objc2ClassData.reserved = 0;

    objc2ClassData.ivarLayout = [cursor readInt32];
    objc2ClassData.name = [cursor readInt32];
    objc2ClassData.baseMethods = [cursor readInt32];
    objc2ClassData.baseProtocols = [cursor readInt32];
    objc2ClassData.ivars = [cursor readInt32];
    objc2ClassData.weakIvarLayout = [cursor readInt32];
    objc2ClassData.baseProperties = [cursor readInt32];

    //NSLog(@"objc2ClassData 32");
    //NSLog(@"%08x %08x %08x %08x", objc2ClassData.flags, objc2ClassData.instanceStart, objc2ClassData.instanceSize, objc2ClassData.reserved);

    //NSLog(@"%08lx %08lx %08lx %08lx", objc2ClassData.ivarLayout, objc2ClassData.name, objc2ClassData.baseMethods, objc2ClassData.baseProtocols);
    //NSLog(@"%08lx %08lx %08lx %08lx", objc2ClassData.ivars, objc2ClassData.weakIvarLayout, objc2ClassData.baseProperties);
    str = [machOFile stringAtAddress:objc2ClassData.name];
    //NSLog(@"name = %@", str);

    aClass = [[[CDOCClass alloc] init] autorelease];
    [aClass setName:str];

    for (CDOCMethod *method in [self loadMethodsAtAddress:objc2ClassData.baseMethods])
        [aClass addInstanceMethod:method];

    [aClass setIvars:[self loadIvarsAtAddress:objc2ClassData.ivars]];

    [cursor release];

    if (objc2Class.superclass == 0) {
        [aClass setSuperClassName:[machOFile externalClassNameForAddress:address + sizeof(objc2Class.isa)]];
    } else {
        if ([machOFile hasRelocationEntryForAddress:address + sizeof(objc2Class.isa)]) {
            [aClass setSuperClassName:[machOFile externalClassNameForAddress:address + sizeof(objc2Class.isa)]];
            NSLog(@"got external class name: %@", [aClass superClassName]);
        } else {
            CDOCClass *sc;

            sc = [self loadClassAtAddress:objc2Class.superclass];
            [aClass setSuperClassName:[sc name]];
        }
    }

    for (CDOCMethod *method in [self loadMethodsOfMetaClassAtAddress:objc2Class.isa])
        [aClass addClassMethod:method];

    // Process protocols
    for (CDOCProtocol *protocol in [self uniquedProtocolListAtAddress:objc2ClassData.baseProtocols])
        [aClass addProtocol:protocol];

    for (CDOCProperty *property in [self loadPropertiesAtAddress:objc2ClassData.baseProperties])
        [aClass addProperty:property];

    return aClass;
}

- (NSArray *)loadPropertiesAtAddress:(uint32_t)address;
{
    NSMutableArray *properties;

    properties = [NSMutableArray array];
    if (address != 0) {
        CDDataCursor *cursor;
        struct cd_objc2_list_header listHeader;
        uint32_t index;

        cursor = [[CDDataCursor alloc] initWithData:[machOFile data]];
        [cursor setByteOrder:[machOFile byteOrder]];
        [cursor setOffset:[machOFile dataOffsetForAddress:address]];
        NSParameterAssert([cursor offset] != 0);
        //NSLog(@"property list data offset: %lu", [cursor offset]);

        listHeader.entsize = [cursor readInt32];
        listHeader.count = [cursor readInt32];
        NSParameterAssert(listHeader.entsize == 8);

        for (index = 0; index < listHeader.count; index++) {
            struct cd_objc2_property_32 objc2Property;
            NSString *name, *attributes;
            CDOCProperty *property;

            objc2Property.name = [cursor readInt32];
            objc2Property.attributes = [cursor readInt32];
            name = [machOFile stringAtAddress:objc2Property.name];
            attributes = [machOFile stringAtAddress:objc2Property.attributes];

            property = [[CDOCProperty alloc] initWithName:name attributes:attributes];
            [properties addObject:property];
            [property release];
        }

        [cursor release];
    }

    return properties;
}

// This just gets the methods.
- (NSArray *)loadMethodsOfMetaClassAtAddress:(uint32_t)address;
{
    struct cd_objc2_class_32 objc2Class;
    struct cd_objc2_class_ro_t_32 objc2ClassData;
    CDDataCursor *cursor;

    if (address == 0)
        return nil;

    cursor = [[CDDataCursor alloc] initWithData:[machOFile data]];
    [cursor setByteOrder:[machOFile byteOrder]];
    [cursor setOffset:[machOFile dataOffsetForAddress:address]];
    NSParameterAssert([cursor offset] != 0);

    objc2Class.isa = [cursor readInt32];
    objc2Class.superclass = [cursor readInt32];
    objc2Class.cache = [cursor readInt32];
    objc2Class.vtable = [cursor readInt32];
    objc2Class.data = [cursor readInt32];
    objc2Class.reserved1 = [cursor readInt32];
    objc2Class.reserved2 = [cursor readInt32];
    objc2Class.reserved3 = [cursor readInt32];
    //NSLog(@"%08lx %08lx %08lx %08lx", objc2Class.isa, objc2Class.superclass, objc2Class.cache, objc2Class.vtable);
    //NSLog(@"%08lx %08lx %08lx %08lx", objc2Class.data, objc2Class.reserved1, objc2Class.reserved2, objc2Class.reserved3);

    NSParameterAssert(objc2Class.data != 0);
    [cursor setOffset:[machOFile dataOffsetForAddress:objc2Class.data]];
    objc2ClassData.flags = [cursor readInt32];
    objc2ClassData.instanceStart = [cursor readInt32];
    objc2ClassData.instanceSize = [cursor readInt32];
    //objc2ClassData.reserved = [cursor readInt32];
    objc2ClassData.reserved = 0;

    objc2ClassData.ivarLayout = [cursor readInt32];
    objc2ClassData.name = [cursor readInt32];
    objc2ClassData.baseMethods = [cursor readInt32];
    objc2ClassData.baseProtocols = [cursor readInt32];
    objc2ClassData.ivars = [cursor readInt32];
    objc2ClassData.weakIvarLayout = [cursor readInt32];
    objc2ClassData.baseProperties = [cursor readInt32];

    [cursor release];

    return [self loadMethodsAtAddress:objc2ClassData.baseMethods];
}

- (NSArray *)loadMethodsAtAddress:(uint32_t)address;
{
    NSMutableArray *methods;

    methods = [NSMutableArray array];

    if (address != 0) {
        CDDataCursor *cursor;
        struct cd_objc2_list_header listHeader;
        uint32_t index;

        cursor = [[CDDataCursor alloc] initWithData:[machOFile data]];
        [cursor setByteOrder:[machOFile byteOrder]];
        [cursor setOffset:[machOFile dataOffsetForAddress:address]];
        NSParameterAssert([cursor offset] != 0);
        //NSLog(@"method list data offset: %lu", [cursor offset]);

        listHeader.entsize = [cursor readInt32];
        listHeader.count = [cursor readInt32];
        //NSLog(@"entsize: %u", listHeader.entsize);
        NSParameterAssert(listHeader.entsize == 12);

        for (index = 0; index < listHeader.count; index++) {
            struct cd_objc2_method_32 objc2Method;
            NSString *name, *types;
            CDOCMethod *method;

            objc2Method.name = [cursor readInt32];
            objc2Method.types = [cursor readInt32];
            objc2Method.imp = [cursor readInt32];
            name = [machOFile stringAtAddress:objc2Method.name];
            types = [machOFile stringAtAddress:objc2Method.types];

            //NSLog(@"%3u: %08lx %08lx %08lx", index, objc2Method.name, objc2Method.types, objc2Method.imp);
            //NSLog(@"name: %@", name);
            //NSLog(@"types: %@", types);

            method = [[CDOCMethod alloc] initWithName:name type:types imp:objc2Method.imp];
            [methods addObject:method];
            [method release];
        }
    }

    return [methods reversedArray];
}

- (NSArray *)loadIvarsAtAddress:(uint32_t)address;
{
    NSMutableArray *ivars;

    ivars = [NSMutableArray array];

    if (address != 0) {
        CDDataCursor *cursor;
        struct cd_objc2_list_header listHeader;
        uint32_t index;

        cursor = [[CDDataCursor alloc] initWithData:[machOFile data]];
        [cursor setByteOrder:[machOFile byteOrder]];
        [cursor setOffset:[machOFile dataOffsetForAddress:address]];
        NSParameterAssert([cursor offset] != 0);
        //NSLog(@"ivar list data offset: %lu", [cursor offset]);

        listHeader.entsize = [cursor readInt32];
        listHeader.count = [cursor readInt32];
        NSParameterAssert(listHeader.entsize == 20);

        for (index = 0; index < listHeader.count; index++) {
            struct cd_objc2_ivar_32 objc2Ivar;
            CDOCIvar *ivar;

            objc2Ivar.offset = [cursor readInt32];
            objc2Ivar.name = [cursor readInt32];
            objc2Ivar.type = [cursor readInt32];
            objc2Ivar.alignment = [cursor readInt32];
            objc2Ivar.size = [cursor readInt32];

            if (objc2Ivar.name != 0) {
                NSString *name, *type;

                name = [machOFile stringAtAddress:objc2Ivar.name];
                type = [machOFile stringAtAddress:objc2Ivar.type];

                ivar = [[CDOCIvar alloc] initWithName:name type:type offset:objc2Ivar.offset];
                [ivars addObject:ivar];
                [ivar release];
            } else {
                //NSLog(@"%08lx %08lx %08lx  %08x %08x", objc2Ivar.offset, objc2Ivar.name, objc2Ivar.type, objc2Ivar.alignment, objc2Ivar.size);
            }
        }
    }

    return ivars;
}

// Returns list of uniqued protocols.
- (NSArray *)uniquedProtocolListAtAddress:(uint32_t)address;
{
    NSMutableArray *protocols;

    protocols = [[[NSMutableArray alloc] init] autorelease];;

    if (address != 0) {
        CDDataCursor *cursor;
        uint32_t count, index;

        cursor = [[CDDataCursor alloc] initWithData:[machOFile data]];
        [cursor setByteOrder:[machOFile byteOrder]];
        [cursor setOffset:[machOFile dataOffsetForAddress:address]];

        count = [cursor readInt32];
        for (index = 0; index < count; index++) {
            uint32_t val;
            CDOCProtocol *protocol, *uniqueProtocol;

            val = [cursor readInt32];
            if (val == 0) {
                NSLog(@"Warning: protocol address in protocol list was 0.");
            } else {
                protocol = [protocolsByAddress objectForKey:[NSNumber numberWithUnsignedInteger:val]];
                if (protocol != nil) {
                    uniqueProtocol = [protocolsByName objectForKey:[protocol name]];
                    if (uniqueProtocol != nil)
                        [protocols addObject:uniqueProtocol];
                }
            }
        }

        [cursor release];
    }

    return protocols;
}

@end
