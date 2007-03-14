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

void swap_cd_objc_module(struct cd_objc_module *cd_objc_module)
{
    cd_objc_module->version = NSSwapLong(cd_objc_module->version);
    cd_objc_module->size = NSSwapLong(cd_objc_module->size);
    cd_objc_module->name = NSSwapLong(cd_objc_module->name);
    cd_objc_module->symtab = NSSwapLong(cd_objc_module->symtab);
}

void swap_cd_objc_symtab(struct cd_objc_symtab *cd_objc_symtab)
{
    cd_objc_symtab->sel_ref_cnt = NSSwapLong(cd_objc_symtab->sel_ref_cnt);
    cd_objc_symtab->refs = NSSwapLong(cd_objc_symtab->refs);
    cd_objc_symtab->cls_def_count = NSSwapShort(cd_objc_symtab->cls_def_count);
    cd_objc_symtab->cat_def_count = NSSwapShort(cd_objc_symtab->cat_def_count);
}

void swap_cd_objc_class(struct cd_objc_class *cd_objc_class)
{
    cd_objc_class->isa = NSSwapLong(cd_objc_class->isa);
    cd_objc_class->super_class = NSSwapLong(cd_objc_class->super_class);
    cd_objc_class->name = NSSwapLong(cd_objc_class->name);
    cd_objc_class->version = NSSwapLong(cd_objc_class->version);
    cd_objc_class->info = NSSwapLong(cd_objc_class->info);
    cd_objc_class->instance_size = NSSwapLong(cd_objc_class->instance_size);
    cd_objc_class->ivars = NSSwapLong(cd_objc_class->ivars);
    cd_objc_class->methods = NSSwapLong(cd_objc_class->methods);
    cd_objc_class->cache = NSSwapLong(cd_objc_class->cache);
    cd_objc_class->protocols = NSSwapLong(cd_objc_class->protocols);
}

void swap_cd_objc_category(struct cd_objc_category *cd_objc_category)
{
    cd_objc_category->category_name = NSSwapLong(cd_objc_category->category_name);
    cd_objc_category->class_name = NSSwapLong(cd_objc_category->class_name);
    cd_objc_category->methods = NSSwapLong(cd_objc_category->methods);
    cd_objc_category->class_methods = NSSwapLong(cd_objc_category->class_methods);
    cd_objc_category->protocols = NSSwapLong(cd_objc_category->protocols);
}

void swap_cd_objc_ivar_list(struct cd_objc_ivar_list *cd_objc_ivar_list)
{
    cd_objc_ivar_list->ivar_count = NSSwapLong(cd_objc_ivar_list->ivar_count);
}

void swap_cd_objc_ivar(struct cd_objc_ivar *cd_objc_ivar)
{
    cd_objc_ivar->name = NSSwapLong(cd_objc_ivar->name);
    cd_objc_ivar->type = NSSwapLong(cd_objc_ivar->type);
    cd_objc_ivar->offset = NSSwapInt(cd_objc_ivar->offset);
}

void swap_cd_objc_method_list(struct cd_objc_method_list *cd_objc_method_list)
{
    cd_objc_method_list->method_count = NSSwapLong(cd_objc_method_list->method_count);
}

void swap_cd_objc_method(struct cd_objc_method *cd_objc_method)
{
    cd_objc_method->name = NSSwapLong(cd_objc_method->name);
    cd_objc_method->types = NSSwapLong(cd_objc_method->types);
    cd_objc_method->imp = NSSwapLong(cd_objc_method->imp);
}

void swap_cd_objc_protocol_list(struct cd_objc_protocol_list *cd_objc_protocol_list)
{
    cd_objc_protocol_list->next = NSSwapLong(cd_objc_protocol_list->next);
    cd_objc_protocol_list->count = NSSwapLong(cd_objc_protocol_list->count);
}

void swap_cd_objc_protocol(struct cd_objc_protocol *cd_objc_protocol)
{
    cd_objc_protocol->isa = NSSwapLong(cd_objc_protocol->isa);
    cd_objc_protocol->protocol_name = NSSwapLong(cd_objc_protocol->protocol_name);
    cd_objc_protocol->protocol_list = NSSwapLong(cd_objc_protocol->protocol_list);
    cd_objc_protocol->instance_methods = NSSwapLong(cd_objc_protocol->instance_methods);
    cd_objc_protocol->class_methods = NSSwapLong(cd_objc_protocol->class_methods);
}

void swap_cd_objc_protocol_method_list(struct cd_objc_protocol_method_list *cd_objc_protocol_method_list)
{
    cd_objc_protocol_method_list->method_count = NSSwapLong(cd_objc_protocol_method_list->method_count);
}

void swap_cd_objc_protocol_method(struct cd_objc_protocol_method *cd_objc_protocol_method)
{
    cd_objc_protocol_method->name = NSSwapLong(cd_objc_protocol_method->name);
    cd_objc_protocol_method->types = NSSwapLong(cd_objc_protocol_method->types);
}

@implementation CDObjCSegmentProcessor (Private)

- (void)processModules;
{
    CDSegmentCommand *objcSegment;
    CDSection *moduleSection;
    const void *ptr;
    struct cd_objc_module objcModule;
    int count, index;

    objcSegment = [machOFile segmentWithName:@"__OBJC"];
    moduleSection = [objcSegment sectionWithName:@"__module_info"];

    ptr = [moduleSection dataPointer];
    count = [moduleSection size] / sizeof(struct cd_objc_module);
    for (index = 0; index < count; index++, ptr += sizeof(struct cd_objc_module)) {
        CDSegmentCommand *aSegment;
        CDOCModule *aModule;

        objcModule = *(struct cd_objc_module *)ptr;
        if ([machOFile hasDifferentByteOrder] == YES)
            swap_cd_objc_module(&objcModule);

        assert(objcModule.size == sizeof(struct cd_objc_module)); // Because this is what we're assuming.
        aSegment = [machOFile segmentContainingAddress:objcModule.symtab];

        aModule = [[CDOCModule alloc] init];
        [aModule setVersion:objcModule.version];
        [aModule setName:[machOFile stringFromVMAddr:objcModule.name]];
        [aModule setSymtab:[self processSymtab:objcModule.symtab]];
        [modules addObject:aModule];

        [aModule release];
    }
}

- (CDOCSymtab *)processSymtab:(unsigned long)symtab;
{
    CDOCSymtab *aSymtab;

    const void *ptr;
    struct cd_objc_symtab objcSymtab;
    const unsigned long *defs;
    int index, defIndex;
    NSMutableArray *classes, *categories;

    // TODO: Should we convert to pointer here or in caller?
    ptr = [machOFile pointerFromVMAddr:symtab segmentName:@"__OBJC"];
    if (ptr == NULL) {
        return nil;
    }

    objcSymtab = *(struct cd_objc_symtab *)ptr;
    if ([machOFile hasDifferentByteOrder] == YES)
        swap_cd_objc_symtab(&objcSymtab);

    aSymtab = [[[CDOCSymtab alloc] init] autorelease];
    classes = [[NSMutableArray alloc] init];
    categories = [[NSMutableArray alloc] init];

    defs = (unsigned long *)(ptr + sizeof(struct cd_objc_symtab));
    defIndex = 0;

    if (objcSymtab.cls_def_count > 0) {
        for (index = 0; index < objcSymtab.cls_def_count; index++, defs++, defIndex++) {
            CDOCClass *aClass;

            if ([machOFile hasDifferentByteOrder] == YES)
                aClass = [self processClassDefinition:NSSwapLong(*defs)];
            else
                aClass = [self processClassDefinition:*defs];

            if (aClass != nil)
                [classes addObject:aClass];
        }
    }

    [aSymtab setClasses:[NSArray arrayWithArray:classes]];

    if (objcSymtab.cat_def_count > 0) {
        for (index = 0; index < objcSymtab.cat_def_count; index++, defs++, defIndex++) {
            CDOCCategory *aCategory;

            if ([machOFile hasDifferentByteOrder] == YES)
                aCategory = [self processCategoryDefinition:NSSwapLong(*defs)];
            else
                aCategory = [self processCategoryDefinition:*defs];

            if (aCategory != nil)
                [categories addObject:aCategory];
        }
    }

    [aSymtab setCategories:[NSArray arrayWithArray:categories]];

    [classes release];
    [categories release];

    return aSymtab;
}

- (CDOCClass *)processClassDefinition:(unsigned long)defRef;
{
    const void *ptr;
    struct cd_objc_class objcClass;
    CDOCClass *aClass;
    int index;
    NSString *name;

    ptr = [machOFile pointerFromVMAddr:defRef];
    if (ptr == NULL)
        return nil;

    objcClass = *(struct cd_objc_class *)ptr;
    if ([machOFile hasDifferentByteOrder] == YES)
        swap_cd_objc_class(&objcClass);

    name = [machOFile stringFromVMAddr:objcClass.name];
    if (name == nil)
        return nil;

    aClass = [[[CDOCClass alloc] init] autorelease];
    [aClass setName:name];
    [aClass setSuperClassName:[machOFile stringFromVMAddr:objcClass.super_class]];

    // Process ivars
    if (objcClass.ivars != 0) {
        ptr = [machOFile pointerFromVMAddr:objcClass.ivars];

        if (ptr != NULL) {
            struct cd_objc_ivar_list ivar_list;
            struct cd_objc_ivar ivar;
            NSMutableArray *ivars;

            ivar_list = *(struct cd_objc_ivar_list *)ptr;
            if ([machOFile hasDifferentByteOrder] == YES)
                swap_cd_objc_ivar_list(&ivar_list);

            ptr += sizeof(struct cd_objc_ivar_list);
            ivars = [[NSMutableArray alloc] init];

            for (index = 0; index < ivar_list.ivar_count; index++, ptr += sizeof(struct cd_objc_ivar)) { // TODO (2005-07-28): Not sure about that increment for ptr2
                NSString *name, *type;

                ivar = *(struct cd_objc_ivar *)ptr;
                if ([machOFile hasDifferentByteOrder] == YES)
                    swap_cd_objc_ivar(&ivar);

                name = [machOFile stringFromVMAddr:ivar.name];
                type = [machOFile stringFromVMAddr:ivar.type];
                if (name != nil && type != nil) {
                    CDOCIvar *anIvar;

                    anIvar = [[CDOCIvar alloc] initWithName:name type:type offset:ivar.offset];
                    [ivars addObject:anIvar];
                    [anIvar release];
                }
            }

            [aClass setIvars:[NSArray arrayWithArray:ivars]];
            [ivars release];
        }
    }

    // Process methods
    [aClass setInstanceMethods:[self processMethods:objcClass.methods]];

    // Process meta class
    {
        ptr = [machOFile pointerFromVMAddr:objcClass.isa];
        if (ptr != NULL) {
            struct cd_objc_class metaClass;

            metaClass = *(struct cd_objc_class *)ptr;
            if ([machOFile hasDifferentByteOrder] == YES)
                swap_cd_objc_class(&metaClass);
            //assert(metaClass.info & CLS_CLASS);

            // Process class methods
            [aClass setClassMethods:[self processMethods:metaClass.methods]];
        }
    }

    // Process protocols
    [aClass addProtocolsFromArray:[self processProtocolList:objcClass.protocols]];

    return aClass;
}

- (NSArray *)processProtocolList:(unsigned long)protocolListAddr;
{
    const void *ptr;
    struct cd_objc_protocol_list protocolList;
    const unsigned long *protocolPtrs;
    NSMutableArray *protocols;
    int index;

    protocols = [[[NSMutableArray alloc] init] autorelease];;

    if (protocolListAddr == 0)
        return protocols;

    ptr = [machOFile pointerFromVMAddr:protocolListAddr];
    if (ptr == NULL)
        return nil;

    protocolList = *(struct cd_objc_protocol_list *)ptr;
    if ([machOFile hasDifferentByteOrder] == YES)
        swap_cd_objc_protocol_list(&protocolList);

    protocolPtrs = ptr + sizeof(struct cd_objc_protocol_list);
    for (index = 0; index < protocolList.count; index++, protocolPtrs++) {
        CDOCProtocol *protocol;

        if ([machOFile hasDifferentByteOrder] == YES)
            protocol = [self processProtocol:NSSwapLong(*protocolPtrs)];
        else
            protocol = [self processProtocol:*protocolPtrs];

        if (protocol != nil)
            [protocols addObject:protocol];
    }

    return protocols;
}

- (CDOCProtocol *)processProtocol:(unsigned long)protocolAddr;
{
    const void *ptr;
    struct cd_objc_protocol protocol;
    CDOCProtocol *aProtocol;
    NSString *name;
    NSArray *protocols;

    ptr = [machOFile pointerFromVMAddr:protocolAddr];
    if (ptr == NULL)
        return nil;

    protocol = *(struct cd_objc_protocol *)ptr;
    if ([machOFile hasDifferentByteOrder] == YES)
        swap_cd_objc_protocol(&protocol);

    name = [machOFile stringFromVMAddr:protocol.protocol_name];
    if (name == nil)
        return nil;

    protocols = [self processProtocolList:protocol.protocol_list];

    aProtocol = [protocolsByName objectForKey:name];
    if (aProtocol == nil) {
        aProtocol = [[[CDOCProtocol alloc] init] autorelease];
        [aProtocol setName:name];

        [protocolsByName setObject:aProtocol forKey:name];
    }

    [aProtocol addProtocolsFromArray:protocols];
    if ([[aProtocol instanceMethods] count] == 0)
        [aProtocol setInstanceMethods:[self processProtocolMethods:protocol.instance_methods]];

    if ([[aProtocol classMethods] count] == 0)
        [aProtocol setClassMethods:[self processProtocolMethods:protocol.class_methods]];

    // TODO (2003-12-09): Maybe we should add any missing methods.  But then we'd lose the original order.

    return aProtocol;
}

- (NSArray *)processProtocolMethods:(unsigned long)methodsAddr;
{
    const void *ptr;
    NSMutableArray *methods;
    struct cd_objc_protocol_method_list methodList;
    struct cd_objc_protocol_method method;
    int index;

    methods = [NSMutableArray array];
    if (methodsAddr == 0)
        return methods;

    ptr = [machOFile pointerFromVMAddr:methodsAddr];
    if (ptr == NULL)
        return nil;

    methodList = *(struct cd_objc_protocol_method_list *)ptr;
    if ([machOFile hasDifferentByteOrder] == YES)
        swap_cd_objc_protocol_method_list(&methodList);

    ptr += sizeof(struct cd_objc_protocol_method_list);

    for (index = 0; index < methodList.method_count; index++, ptr += sizeof(struct cd_objc_protocol_method)) {
        NSString *name, *type;

        method = *(struct cd_objc_protocol_method *)ptr;
        if ([machOFile hasDifferentByteOrder] == YES)
            swap_cd_objc_protocol_method(&method);

        name = [machOFile stringFromVMAddr:method.name];
        type = [machOFile stringFromVMAddr:method.types];
        if (name != nil && type != nil) {
            CDOCMethod *aMethod;

            aMethod = [[CDOCMethod alloc] initWithName:name type:type imp:0];
            [methods addObject:aMethod];
            [aMethod release];
        }
    }

    return [methods reversedArray];
}

- (NSArray *)processMethods:(unsigned long)methodsAddr;
{
    const void *ptr;
    NSMutableArray *methods;
    struct cd_objc_method_list methodList;
    struct cd_objc_method method;
    int index;

    methods = [NSMutableArray array];
    if (methodsAddr == 0)
        return methods;

    ptr = [machOFile pointerFromVMAddr:methodsAddr];
    if (ptr == NULL)
        return nil;

    methodList = *(struct cd_objc_method_list *)ptr;
    if ([machOFile hasDifferentByteOrder] == YES)
        swap_cd_objc_method_list(&methodList);

    ptr += sizeof(struct cd_objc_method_list);

    for (index = 0; index < methodList.method_count; index++, ptr += sizeof(struct cd_objc_method)) {
        NSString *name, *type;

        method = *(struct cd_objc_method *)ptr;
        if ([machOFile hasDifferentByteOrder] == YES)
            swap_cd_objc_method(&method);

        name = [machOFile stringFromVMAddr:method.name];
        type = [machOFile stringFromVMAddr:method.types];
        if (name != nil && type != nil) {
            CDOCMethod *aMethod;

            aMethod = [[CDOCMethod alloc] initWithName:name type:type imp:method.imp];
            [methods addObject:aMethod];
            [aMethod release];
        }
    }

    return [methods reversedArray];
}

- (CDOCCategory *)processCategoryDefinition:(unsigned long)defRef;
{
    const void *ptr;
    struct cd_objc_category objcCategory;
    NSString *name;
    CDOCCategory *aCategory;

    ptr = [machOFile pointerFromVMAddr:defRef];
    if (ptr == NULL)
        return nil;

    objcCategory = *(struct cd_objc_category *)ptr;
    if ([machOFile hasDifferentByteOrder] == YES)
        swap_cd_objc_category(&objcCategory);

    name = [machOFile stringFromVMAddr:objcCategory.category_name];
    if (name == nil)
        return nil;

    aCategory = [[[CDOCCategory alloc] init] autorelease];
    [aCategory setName:name];
    [aCategory setClassName:[machOFile stringFromVMAddr:objcCategory.class_name]];

    // Process methods
    [aCategory setInstanceMethods:[self processMethods:objcCategory.methods]];
    [aCategory setClassMethods:[self processMethods:objcCategory.class_methods]];

    // Process protocols
    [aCategory addProtocolsFromArray:[self processProtocolList:objcCategory.protocols]];

    return aCategory;
}

// Protocols can reference other protocols, so we can't try to create them
// in order.  Instead we create them lazily and just make sure we reference
// all available protocols.

- (void)processProtocolSection;
{
    CDSegmentCommand *objcSegment;
    CDSection *protocolSection;
    unsigned long addr;
    CDOCProtocol *aProtocol;
    int count, index;

    objcSegment = [machOFile segmentWithName:@"__OBJC"];
    protocolSection = [objcSegment sectionWithName:@"__protocol"];

    addr = [protocolSection addr];

    count = [protocolSection size] / sizeof(struct cd_objc_protocol);
    for (index = 0; index < count; index++, addr += sizeof(struct cd_objc_protocol))
        aProtocol = [self processProtocol:addr];
}

- (void)checkUnreferencedProtocols;
{
    NSLog(@" > %s", _cmd);
    NSLog(@"<  %s", _cmd);
}

@end
