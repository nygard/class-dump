// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDObjectiveC2Processor.h"

#import "CDMachOFile.h"
#import "CDSection.h"
#import "CDLCSegment.h"
#import "CDMachOFileDataCursor.h"
#import "CDOCClass.h"
#import "CDOCMethod.h"
#import "CDOCIvar.h"
#import "CDLCSymbolTable.h"
#import "CDOCCategory.h"
#import "CDClassDump.h"
#import "CDSymbol.h"
#import "CDOCProperty.h"
#import "cd_objc2.h"

@implementation CDObjectiveC2Processor
{
}

- (void)loadProtocols;
{
    CDLCSegment *segment = [self.machOFile segmentWithName:@"__DATA"];
    CDSection *section = [segment sectionWithName:@"__objc_protolist"];
    
    CDMachOFileDataCursor *cursor = [[CDMachOFileDataCursor alloc] initWithSection:section];
    while ([cursor isAtEnd] == NO)
        [self protocolAtAddress:[cursor readPtr]];
    
    [self createUniquedProtocols];
}

- (void)loadClasses;
{
    CDLCSegment *segment = [self.machOFile segmentWithName:@"__DATA"];
    CDSection *section = [segment sectionWithName:@"__objc_classlist"];
    
    CDMachOFileDataCursor *cursor = [[CDMachOFileDataCursor alloc] initWithSection:section];
    while ([cursor isAtEnd] == NO) {
        uint64_t val = [cursor readPtr];
        CDOCClass *aClass = [self loadClassAtAddress:val];
        if (aClass != nil) {
            [self addClass:aClass withAddress:val];
        }
    }
}

- (void)loadCategories;
{
    CDLCSegment *segment = [self.machOFile segmentWithName:@"__DATA"];
    CDSection *section = [segment sectionWithName:@"__objc_catlist"];
    
    CDMachOFileDataCursor *cursor = [[CDMachOFileDataCursor alloc] initWithSection:section];
    while ([cursor isAtEnd] == NO) {
        CDOCCategory *category = [self loadCategoryAtAddress:[cursor readPtr]];
        [self addCategory:category];
    }
}

- (CDOCProtocol *)protocolAtAddress:(uint64_t)address;
{
    if (address == 0)
        return nil;
    
    CDOCProtocol *protocol = [self protocolWithAddress:address];
    if (protocol == nil) {
        protocol = [[CDOCProtocol alloc] init];
        [self setProtocol:protocol withAddress:address];
        
        CDMachOFileDataCursor *cursor = [[CDMachOFileDataCursor alloc] initWithFile:self.machOFile address:address];
        NSParameterAssert([cursor offset] != 0);
        
        struct cd_objc2_protocol objc2Protocol;
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
        
        NSString *str = [self.machOFile stringAtAddress:objc2Protocol.name];
        [protocol setName:str];
        
        if (objc2Protocol.protocols != 0) {
            [cursor setAddress:objc2Protocol.protocols];
            uint64_t count = [cursor readPtr];
            for (uint64_t index = 0; index < count; index++) {
                uint64_t val = [cursor readPtr];
                CDOCProtocol *anotherProtocol = [self protocolAtAddress:val];
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
    }
    
    return protocol;
}

- (CDOCCategory *)loadCategoryAtAddress:(uint64_t)address;
{
    if (address == 0)
        return nil;
    
    CDMachOFileDataCursor *cursor = [[CDMachOFileDataCursor alloc] initWithFile:self.machOFile address:address];
    NSParameterAssert([cursor offset] != 0);
    
    struct cd_objc2_category objc2Category;
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
    
    CDOCCategory *category = [[CDOCCategory alloc] init];
    NSString *str = [self.machOFile stringAtAddress:objc2Category.name];
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
        uint64_t classNameAddress = address + [self.machOFile ptrSize];
        
        if ([self.machOFile hasRelocationEntryForAddress2:classNameAddress]) {
            [category setClassName:[self.machOFile externalClassNameForAddress2:classNameAddress]];
            //NSLog(@"category: got external class name (2): %@", [category className]);
        } else if ([self.machOFile hasRelocationEntryForAddress:classNameAddress]) {
            [category setClassName:[self.machOFile externalClassNameForAddress:classNameAddress]];
            //NSLog(@"category: got external class name (1): %@", [aClass className]);
        } else if (objc2Category.class != 0) {
            CDOCClass *aClass = [self classWithAddress:objc2Category.class];
            [category setClassName:[aClass name]];
        }
    }
    
    return category;
}

- (CDOCClass *)loadClassAtAddress:(uint64_t)address;
{
    if (address == 0)
        return nil;
    
    //NSLog(@"%s, address=%016lx", __cmd, address);
    
    CDMachOFileDataCursor *cursor = [[CDMachOFileDataCursor alloc] initWithFile:self.machOFile address:address];
    NSParameterAssert([cursor offset] != 0);
    
    struct cd_objc2_class objc2Class;
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

    struct cd_objc2_class_ro_t objc2ClassData;
    objc2ClassData.flags = [cursor readInt32];
    objc2ClassData.instanceStart = [cursor readInt32];
    objc2ClassData.instanceSize = [cursor readInt32];
    if ([self.machOFile uses64BitABI])
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
    NSString *str = [self.machOFile stringAtAddress:objc2ClassData.name];
    //NSLog(@"name = %@", str);
    
    CDOCClass *aClass = [[CDOCClass alloc] init];
    [aClass setName:str];
    
    for (CDOCMethod *method in [self loadMethodsAtAddress:objc2ClassData.baseMethods])
        [aClass addInstanceMethod:method];
    
    [aClass setIvars:[self loadIvarsAtAddress:objc2ClassData.ivars]];
    
    {
        CDSymbol *classSymbol = [[self.machOFile symbolTable] symbolForClass:str];
        
        if (classSymbol != nil)
            aClass.isExported = [classSymbol isExternal];
    }
    
    {
        uint64_t classNameAddress = address + [self.machOFile ptrSize];
        
        if ([self.machOFile hasRelocationEntryForAddress2:classNameAddress]) {
            [aClass setSuperClassName:[self.machOFile externalClassNameForAddress2:classNameAddress]];
            //NSLog(@"class: got external class name (2): %@", [aClass superClassName]);
        } else if ([self.machOFile hasRelocationEntryForAddress:classNameAddress]) {
            [aClass setSuperClassName:[self.machOFile externalClassNameForAddress:classNameAddress]];
            //NSLog(@"class: got external class name (1): %@", [aClass superClassName]);
        } else if (objc2Class.superclass != 0) {
            CDOCClass *sc = [self loadClassAtAddress:objc2Class.superclass];
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
    NSMutableArray *properties = [NSMutableArray array];
    if (address != 0) {
        struct cd_objc2_list_header listHeader;
        
        CDMachOFileDataCursor *cursor = [[CDMachOFileDataCursor alloc] initWithFile:self.machOFile address:address];
        NSParameterAssert([cursor offset] != 0);
        //NSLog(@"property list data offset: %lu", [cursor offset]);
        
        listHeader.entsize = [cursor readInt32];
        listHeader.count = [cursor readInt32];
        NSParameterAssert(listHeader.entsize == ([self.machOFile uses64BitABI] ? 16 : 8));
        
        for (uint32_t index = 0; index < listHeader.count; index++) {
            struct cd_objc2_property objc2Property;
            
            objc2Property.name = [cursor readPtr];
            objc2Property.attributes = [cursor readPtr];
            NSString *name = [self.machOFile stringAtAddress:objc2Property.name];
            NSString *attributes = [self.machOFile stringAtAddress:objc2Property.attributes];
            
            CDOCProperty *property = [[CDOCProperty alloc] initWithName:name attributes:attributes];
            [properties addObject:property];
        }
    }
    
    return properties;
}

// This just gets the methods.
- (NSArray *)loadMethodsOfMetaClassAtAddress:(uint64_t)address;
{
    if (address == 0)
        return nil;
    
    CDMachOFileDataCursor *cursor = [[CDMachOFileDataCursor alloc] initWithFile:self.machOFile address:address];
    NSParameterAssert([cursor offset] != 0);
    
    struct cd_objc2_class objc2Class;
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

    struct cd_objc2_class_ro_t objc2ClassData;
    objc2ClassData.flags = [cursor readInt32];
    objc2ClassData.instanceStart = [cursor readInt32];
    objc2ClassData.instanceSize = [cursor readInt32];
    if ([self.machOFile uses64BitABI])
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
    
    return [self loadMethodsAtAddress:objc2ClassData.baseMethods];
}

- (NSArray *)loadMethodsAtAddress:(uint64_t)address;
{
    NSMutableArray *methods = [NSMutableArray array];
    
    if (address != 0) {
        CDMachOFileDataCursor *cursor = [[CDMachOFileDataCursor alloc] initWithFile:self.machOFile address:address];
        NSParameterAssert([cursor offset] != 0);
        //NSLog(@"method list data offset: %lu", [cursor offset]);
        
        struct cd_objc2_list_header listHeader;
        
        listHeader.entsize = [cursor readInt32];
        listHeader.count = [cursor readInt32];
        NSParameterAssert(listHeader.entsize == ([self.machOFile uses64BitABI] ? 24 : 12));
        
        for (uint32_t index = 0; index < listHeader.count; index++) {
            struct cd_objc2_method objc2Method;
            
            objc2Method.name = [cursor readPtr];
            objc2Method.types = [cursor readPtr];
            objc2Method.imp = [cursor readPtr];
            NSString *name = [self.machOFile stringAtAddress:objc2Method.name];
            NSString *types = [self.machOFile stringAtAddress:objc2Method.types];
            
            //NSLog(@"%3u: %016lx %016lx %016lx", index, objc2Method.name, objc2Method.types, objc2Method.imp);
            //NSLog(@"name: %@", name);
            //NSLog(@"types: %@", types);
            
            CDOCMethod *method = [[CDOCMethod alloc] initWithName:name type:types imp:objc2Method.imp];
            [methods addObject:method];
        }
    }
    
    return [methods reversedArray];
}

- (NSArray *)loadIvarsAtAddress:(uint64_t)address;
{
    NSMutableArray *ivars = [NSMutableArray array];
    
    if (address != 0) {
        CDMachOFileDataCursor *cursor = [[CDMachOFileDataCursor alloc] initWithFile:self.machOFile address:address];
        NSParameterAssert([cursor offset] != 0);
        //NSLog(@"ivar list data offset: %lu", [cursor offset]);
        
        struct cd_objc2_list_header listHeader;
        
        listHeader.entsize = [cursor readInt32];
        listHeader.count = [cursor readInt32];
        NSParameterAssert(listHeader.entsize == ([self.machOFile uses64BitABI] ? 32 : 20));
        
        for (uint32_t index = 0; index < listHeader.count; index++) {
            struct cd_objc2_ivar objc2Ivar;
            
            objc2Ivar.offset = [cursor readPtr];
            objc2Ivar.name = [cursor readPtr];
            objc2Ivar.type = [cursor readPtr];
            objc2Ivar.alignment = [cursor readInt32];
            objc2Ivar.size = [cursor readInt32];
            
            if (objc2Ivar.name != 0) {
                NSString *name = [self.machOFile stringAtAddress:objc2Ivar.name];
                NSString *type = [self.machOFile stringAtAddress:objc2Ivar.type];
                
                CDOCIvar *ivar = [[CDOCIvar alloc] initWithName:name type:type offset:objc2Ivar.offset];
                [ivars addObject:ivar];
            } else {
                //NSLog(@"%016lx %016lx %016lx  %08x %08x", objc2Ivar.offset, objc2Ivar.name, objc2Ivar.type, objc2Ivar.alignment, objc2Ivar.size);
            }
        }
    }
    
    return ivars;
}

// Returns list of uniqued protocols.
- (NSArray *)uniquedProtocolListAtAddress:(uint64_t)address;
{
    NSMutableArray *protocols = [[NSMutableArray alloc] init];;
    
    if (address != 0) {
        CDMachOFileDataCursor *cursor = [[CDMachOFileDataCursor alloc] initWithFile:self.machOFile address:address];
        
        uint64_t count = [cursor readPtr];
        for (uint64_t index = 0; index < count; index++) {
            uint64_t val = [cursor readPtr];
            if (val == 0) {
                NSLog(@"Warning: protocol address in protocol list was 0.");
            } else {
                CDOCProtocol *protocol = [self protocolWithAddress:val];
                if (protocol != nil) {
                    CDOCProtocol *uniqueProtocol = [self protocolForName:[protocol name]];
                    if (uniqueProtocol != nil)
                        [protocols addObject:uniqueProtocol];
                }
            }
        }
    }
    
    return protocols;
}

- (CDSection *)objcImageInfoSection;
{
    return [[self.machOFile segmentWithName:@"__DATA"] sectionWithName:@"__objc_imageinfo"];
}

@end
