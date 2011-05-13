// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2011 Steve Nygard.

#import "CDObjectiveC2Processor.h"

#import "CDMachOFile.h"
#import "CDSection.h"
#import "CDLCSegment.h"
#import "CDMachOFileDataCursor.h"
#import "CDOCClass.h"
#import "CDOCMethod.h"
#import "CDOCIvar.h"
#import "NSArray-Extensions.h"
#import "CDLCSymbolTable.h"
#import "CDOCCategory.h"
#import "CDClassDump.h"
#import "CDSymbol.h"
#import "CDOCProperty.h"
#import "cd_objc2.h"

@implementation CDObjectiveC2Processor

- (void)loadProtocols;
{
    CDLCSegment *segment;
    CDSection *section;
    CDMachOFileDataCursor *cursor;
    
    segment = [machOFile segmentWithName:@"__DATA"];
    section = [segment sectionWithName:@"__objc_protolist"];
    
    cursor = [[CDMachOFileDataCursor alloc] initWithSection:section];
    while ([cursor isAtEnd] == NO)
        [self protocolAtAddress:[cursor readPtr]];
    [cursor release];
    
    [self createUniquedProtocols];
}

- (void)loadClasses;
{
    CDLCSegment *segment;
    CDSection *section;
    CDMachOFileDataCursor *cursor;
    
    segment = [machOFile segmentWithName:@"__DATA"];
    section = [segment sectionWithName:@"__objc_classlist"];
    
    cursor = [[CDMachOFileDataCursor alloc] initWithSection:section];
    while ([cursor isAtEnd] == NO) {
        uint64_t val;
        CDOCClass *aClass;
        
        val = [cursor readPtr];
        aClass = [self loadClassAtAddress:val];
        if (aClass != nil) {
            [classes addObject:aClass];
            [classesByAddress setObject:aClass forKey:[NSNumber numberWithUnsignedLongLong:val]];
        }
    }
    
    [cursor release];
}

- (void)loadCategories;
{
    CDLCSegment *segment;
    CDSection *section;
    CDMachOFileDataCursor *cursor;
    
    segment = [machOFile segmentWithName:@"__DATA"];
    section = [segment sectionWithName:@"__objc_catlist"];
    
    cursor = [[CDMachOFileDataCursor alloc] initWithSection:section];
    while ([cursor isAtEnd] == NO) {
        CDOCCategory *category;
        
        category = [self loadCategoryAtAddress:[cursor readPtr]];
        if (category != nil)
            [categories addObject:category];
    }
    
    [cursor release];
}

- (CDOCProtocol *)protocolAtAddress:(uint64_t)address;
{
    NSNumber *key;
    CDOCProtocol *protocol;
    
    if (address == 0)
        return nil;
    
    key = [NSNumber numberWithUnsignedLongLong:address];
    protocol = [protocolsByAddress objectForKey:key];
    if (protocol == nil) {
        struct cd_objc2_protocol objc2Protocol;
        CDMachOFileDataCursor *cursor;
        NSString *str;
        
        protocol = [[[CDOCProtocol alloc] init] autorelease];
        [protocolsByAddress setObject:protocol forKey:key];
        
        cursor = [[CDMachOFileDataCursor alloc] initWithFile:machOFile address:address];
        NSParameterAssert([cursor offset] != 0);
        
        objc2Protocol.isa = [cursor readPtr];
        objc2Protocol.name = [cursor readPtr];
        objc2Protocol.protocols = [cursor readPtr];
        objc2Protocol.instanceMethods = [cursor readPtr];
        objc2Protocol.classMethods = [cursor readPtr];
        objc2Protocol.optionalInstanceMethods = [cursor readPtr];
        objc2Protocol.optionalClassMethods = [cursor readPtr];
        objc2Protocol.instanceProperties = [cursor readPtr];
        
        //NSLog(@"----------------------------------------");
        //NSLog(@"%016lx %016lx %016lx %016lx", objc2Protocol.isa, objc2Protocol.name, objc2Protocol.protocols, objc2Protocol.instanceMethods);
        //NSLog(@"%016lx %016lx %016lx %016lx", objc2Protocol.classMethods, objc2Protocol.optionalInstanceMethods, objc2Protocol.optionalClassMethods, objc2Protocol.instanceProperties);
        
        str = [machOFile stringAtAddress:objc2Protocol.name];
        [protocol setName:str];
        
        if (objc2Protocol.protocols != 0) {
            uint64_t count, index;
            
            [cursor setAddress:objc2Protocol.protocols];
            count = [cursor readPtr];
            for (index = 0; index < count; index++) {
                uint64_t val;
                CDOCProtocol *anotherProtocol;
                
                val = [cursor readPtr];
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
        
        for (CDOCProperty *property in [self loadPropertiesAtAddress:objc2Protocol.instanceProperties])
            [protocol addProperty:property];
        
        [cursor release];
    }
    
    return protocol;
}

- (CDOCCategory *)loadCategoryAtAddress:(uint64_t)address;
{
    struct cd_objc2_category objc2Category;
    CDMachOFileDataCursor *cursor;
    NSString *str;
    CDOCCategory *category;
    
    if (address == 0)
        return nil;
    
    cursor = [[CDMachOFileDataCursor alloc] initWithFile:machOFile address:address];
    NSParameterAssert([cursor offset] != 0);
    
    objc2Category.name = [cursor readPtr];
    objc2Category.class = [cursor readPtr];
    objc2Category.instanceMethods = [cursor readPtr];
    objc2Category.classMethods = [cursor readPtr];
    objc2Category.protocols = [cursor readPtr];
    objc2Category.instanceProperties = [cursor readPtr];
    objc2Category.v7 = [cursor readPtr];
    objc2Category.v8 = [cursor readPtr];
    //NSLog(@"----------------------------------------");
    //NSLog(@"%016lx %016lx %016lx %016lx", objc2Category.name, objc2Category.class, objc2Category.instanceMethods, objc2Category.classMethods);
    //NSLog(@"%016lx %016lx %016lx %016lx", objc2Category.protocols, objc2Category.instanceProperties, objc2Category.v7, objc2Category.v8);
    
    category = [[[CDOCCategory alloc] init] autorelease];
    str = [machOFile stringAtAddress:objc2Category.name];
    [category setName:str];
    
    for (CDOCMethod *method in [self loadMethodsAtAddress:objc2Category.instanceMethods])
        [category addInstanceMethod:method];
    
    for (CDOCMethod *method in [self loadMethodsAtAddress:objc2Category.classMethods])
        [category addClassMethod:method];
    
    for (CDOCProtocol *protocol in [self uniquedProtocolListAtAddress:objc2Category.protocols])
        [category addProtocol:protocol];
    
    for (CDOCProperty *property in [self loadPropertiesAtAddress:objc2Category.instanceProperties])
        [category addProperty:property];
    
    {
        uint64_t classNameAddress = address + [machOFile ptrSize];
        
        if ([machOFile hasRelocationEntryForAddress2:classNameAddress]) {
            [category setClassName:[machOFile externalClassNameForAddress2:classNameAddress]];
            //NSLog(@"category: got external class name (2): %@", [category className]);
        } else if ([machOFile hasRelocationEntryForAddress:classNameAddress]) {
            [category setClassName:[machOFile externalClassNameForAddress:classNameAddress]];
            //NSLog(@"category: got external class name (1): %@", [aClass className]);
        } else if (objc2Category.class != 0) {
            CDOCClass *aClass;
            
            aClass = [classesByAddress objectForKey:[NSNumber numberWithUnsignedLongLong:objc2Category.class]];
            [category setClassName:[aClass name]];
        }
    }
    
    [cursor release];
    
    return category;
}

- (CDOCClass *)loadClassAtAddress:(uint64_t)address;
{
    struct cd_objc2_class objc2Class;
    struct cd_objc2_class_ro_t objc2ClassData;
    CDMachOFileDataCursor *cursor;
    NSString *str;
    CDOCClass *aClass;
    
    if (address == 0)
        return nil;
    
    //NSLog(@"%s, address=%016lx", __cmd, address);
    
    cursor = [[CDMachOFileDataCursor alloc] initWithFile:machOFile address:address];
    NSParameterAssert([cursor offset] != 0);
    
    objc2Class.isa = [cursor readPtr];
    objc2Class.superclass = [cursor readPtr];
    objc2Class.cache = [cursor readPtr];
    objc2Class.vtable = [cursor readPtr];
    objc2Class.data = [cursor readPtr];
    objc2Class.reserved1 = [cursor readPtr];
    objc2Class.reserved2 = [cursor readPtr];
    objc2Class.reserved3 = [cursor readPtr];
    //NSLog(@"%016lx %016lx %016lx %016lx", objc2Class.isa, objc2Class.superclass, objc2Class.cache, objc2Class.vtable);
    //NSLog(@"%016lx %016lx %016lx %016lx", objc2Class.data, objc2Class.reserved1, objc2Class.reserved2, objc2Class.reserved3);
    
    NSParameterAssert(objc2Class.data != 0);
    [cursor setAddress:objc2Class.data];
    objc2ClassData.flags = [cursor readInt32];
    objc2ClassData.instanceStart = [cursor readInt32];
    objc2ClassData.instanceSize = [cursor readInt32];
    if ([machOFile uses64BitABI])
        objc2ClassData.reserved = [cursor readInt32];
    else
        objc2ClassData.reserved = 0;
    
    objc2ClassData.ivarLayout = [cursor readPtr];
    objc2ClassData.name = [cursor readPtr];
    objc2ClassData.baseMethods = [cursor readPtr];
    objc2ClassData.baseProtocols = [cursor readPtr];
    objc2ClassData.ivars = [cursor readPtr];
    objc2ClassData.weakIvarLayout = [cursor readPtr];
    objc2ClassData.baseProperties = [cursor readPtr];
    
    //NSLog(@"%08x %08x %08x %08x", objc2ClassData.flags, objc2ClassData.instanceStart, objc2ClassData.instanceSize, objc2ClassData.reserved);
    
    //NSLog(@"%016lx %016lx %016lx %016lx", objc2ClassData.ivarLayout, objc2ClassData.name, objc2ClassData.baseMethods, objc2ClassData.baseProtocols);
    //NSLog(@"%016lx %016lx %016lx %016lx", objc2ClassData.ivars, objc2ClassData.weakIvarLayout, objc2ClassData.baseProperties);
    str = [machOFile stringAtAddress:objc2ClassData.name];
    //NSLog(@"name = %@", str);
    
    aClass = [[[CDOCClass alloc] init] autorelease];
    [aClass setName:str];
    
    for (CDOCMethod *method in [self loadMethodsAtAddress:objc2ClassData.baseMethods])
        [aClass addInstanceMethod:method];
    
    [aClass setIvars:[self loadIvarsAtAddress:objc2ClassData.ivars]];
    
    [cursor release];
    
    {
        CDSymbol *classSymbol = [[machOFile symbolTable] symbolForClass:str];
        
        if (classSymbol != nil)
            aClass.isExported = [classSymbol isExternal];
    }
    
    {
        uint64_t classNameAddress = address + [machOFile ptrSize];
        
        if ([machOFile hasRelocationEntryForAddress2:classNameAddress]) {
            [aClass setSuperClassName:[machOFile externalClassNameForAddress2:classNameAddress]];
            //NSLog(@"class: got external class name (2): %@", [aClass superClassName]);
        } else if ([machOFile hasRelocationEntryForAddress:classNameAddress]) {
            [aClass setSuperClassName:[machOFile externalClassNameForAddress:classNameAddress]];
            //NSLog(@"class: got external class name (1): %@", [aClass superClassName]);
        } else if (objc2Class.superclass != 0) {
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

- (NSArray *)loadPropertiesAtAddress:(uint64_t)address;
{
    NSMutableArray *properties;
    
    properties = [NSMutableArray array];
    if (address != 0) {
        CDMachOFileDataCursor *cursor;
        struct cd_objc2_list_header listHeader;
        uint32_t index;
        
        cursor = [[CDMachOFileDataCursor alloc] initWithFile:machOFile address:address];
        NSParameterAssert([cursor offset] != 0);
        //NSLog(@"property list data offset: %lu", [cursor offset]);
        
        listHeader.entsize = [cursor readInt32];
        listHeader.count = [cursor readInt32];
        NSParameterAssert(listHeader.entsize == [machOFile uses64BitABI] ? 16 : 8);
        
        for (index = 0; index < listHeader.count; index++) {
            struct cd_objc2_property objc2Property;
            NSString *name, *attributes;
            CDOCProperty *property;
            
            objc2Property.name = [cursor readPtr];
            objc2Property.attributes = [cursor readPtr];
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
- (NSArray *)loadMethodsOfMetaClassAtAddress:(uint64_t)address;
{
    struct cd_objc2_class objc2Class;
    struct cd_objc2_class_ro_t objc2ClassData;
    CDMachOFileDataCursor *cursor;
    
    if (address == 0)
        return nil;
    
    cursor = [[CDMachOFileDataCursor alloc] initWithFile:machOFile address:address];
    NSParameterAssert([cursor offset] != 0);
    
    objc2Class.isa = [cursor readPtr];
    objc2Class.superclass = [cursor readPtr];
    objc2Class.cache = [cursor readPtr];
    objc2Class.vtable = [cursor readPtr];
    objc2Class.data = [cursor readPtr];
    objc2Class.reserved1 = [cursor readPtr];
    objc2Class.reserved2 = [cursor readPtr];
    objc2Class.reserved3 = [cursor readPtr];
    //NSLog(@"%016lx %016lx %016lx %016lx", objc2Class.isa, objc2Class.superclass, objc2Class.cache, objc2Class.vtable);
    //NSLog(@"%016lx %016lx %016lx %016lx", objc2Class.data, objc2Class.reserved1, objc2Class.reserved2, objc2Class.reserved3);
    
    NSParameterAssert(objc2Class.data != 0);
    [cursor setAddress:objc2Class.data];
    objc2ClassData.flags = [cursor readInt32];
    objc2ClassData.instanceStart = [cursor readInt32];
    objc2ClassData.instanceSize = [cursor readInt32];
    if ([machOFile uses64BitABI])
        objc2ClassData.reserved = [cursor readInt32];
    else
        objc2ClassData.reserved = 0;
    
    objc2ClassData.ivarLayout = [cursor readPtr];
    objc2ClassData.name = [cursor readPtr];
    objc2ClassData.baseMethods = [cursor readPtr];
    objc2ClassData.baseProtocols = [cursor readPtr];
    objc2ClassData.ivars = [cursor readPtr];
    objc2ClassData.weakIvarLayout = [cursor readPtr];
    objc2ClassData.baseProperties = [cursor readPtr];
    
    [cursor release];
    
    return [self loadMethodsAtAddress:objc2ClassData.baseMethods];
}

- (NSArray *)loadMethodsAtAddress:(uint64_t)address;
{
    NSMutableArray *methods;
    
    methods = [NSMutableArray array];
    
    if (address != 0) {
        CDMachOFileDataCursor *cursor;
        struct cd_objc2_list_header listHeader;
        uint32_t index;
        
        cursor = [[CDMachOFileDataCursor alloc] initWithFile:machOFile address:address];
        NSParameterAssert([cursor offset] != 0);
        //NSLog(@"method list data offset: %lu", [cursor offset]);
        
        listHeader.entsize = [cursor readInt32];
        listHeader.count = [cursor readInt32];
        NSParameterAssert(listHeader.entsize == [machOFile uses64BitABI] ? 24 : 12);
        
        for (index = 0; index < listHeader.count; index++) {
            struct cd_objc2_method objc2Method;
            NSString *name, *types;
            CDOCMethod *method;
            
            objc2Method.name = [cursor readPtr];
            objc2Method.types = [cursor readPtr];
            objc2Method.imp = [cursor readPtr];
            name = [machOFile stringAtAddress:objc2Method.name];
            types = [machOFile stringAtAddress:objc2Method.types];
            
            //NSLog(@"%3u: %016lx %016lx %016lx", index, objc2Method.name, objc2Method.types, objc2Method.imp);
            //NSLog(@"name: %@", name);
            //NSLog(@"types: %@", types);
            
            method = [[CDOCMethod alloc] initWithName:name type:types imp:objc2Method.imp];
            [methods addObject:method];
            [method release];
        }
        
        [cursor release];
    }
    
    return [methods reversedArray];
}

- (NSArray *)loadIvarsAtAddress:(uint64_t)address;
{
    NSMutableArray *ivars;
    
    ivars = [NSMutableArray array];
    
    if (address != 0) {
        CDMachOFileDataCursor *cursor;
        struct cd_objc2_list_header listHeader;
        uint32_t index;
        
        cursor = [[CDMachOFileDataCursor alloc] initWithFile:machOFile address:address];
        NSParameterAssert([cursor offset] != 0);
        //NSLog(@"ivar list data offset: %lu", [cursor offset]);
        
        listHeader.entsize = [cursor readInt32];
        listHeader.count = [cursor readInt32];
        NSParameterAssert(listHeader.entsize == [machOFile uses64BitABI] ? 32 : 20);
        
        for (index = 0; index < listHeader.count; index++) {
            struct cd_objc2_ivar objc2Ivar;
            CDOCIvar *ivar;
            
            objc2Ivar.offset = [cursor readPtr];
            objc2Ivar.name = [cursor readPtr];
            objc2Ivar.type = [cursor readPtr];
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
                //NSLog(@"%016lx %016lx %016lx  %08x %08x", objc2Ivar.offset, objc2Ivar.name, objc2Ivar.type, objc2Ivar.alignment, objc2Ivar.size);
            }
        }
        
        [cursor release];
    }
    
    return ivars;
}

// Returns list of uniqued protocols.
- (NSArray *)uniquedProtocolListAtAddress:(uint64_t)address;
{
    NSMutableArray *protocols;
    
    protocols = [[[NSMutableArray alloc] init] autorelease];;
    
    if (address != 0) {
        CDMachOFileDataCursor *cursor;
        uint64_t count, index;
        
        cursor = [[CDMachOFileDataCursor alloc] initWithFile:machOFile address:address];
        
        count = [cursor readPtr];
        for (index = 0; index < count; index++) {
            uint64_t val;
            CDOCProtocol *protocol, *uniqueProtocol;
            
            val = [cursor readPtr];
            if (val == 0) {
                NSLog(@"Warning: protocol address in protocol list was 0.");
            } else {
                protocol = [protocolsByAddress objectForKey:[NSNumber numberWithUnsignedLongLong:val]];
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

- (CDSection *)objcImageInfoSection;
{
    return [[machOFile segmentWithName:@"__DATA"] sectionWithName:@"__objc_imageinfo"];
}

@end
