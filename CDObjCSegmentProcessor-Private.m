//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import "CDObjCSegmentProcessor-Private.h"

#import "rcsid.h"
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

RCS_ID("$Header: /Volumes/Data/tmp/Tools/class-dump/CDObjCSegmentProcessor-Private.m,v 1.6 2004/01/06 02:31:42 nygard Exp $");

@implementation CDObjCSegmentProcessor (Private)

- (void)processModules;
{
    CDSegmentCommand *objcSegment;
    CDSection *moduleSection;
    const struct cd_objc_module *ptr;
    int count, index;

    objcSegment = [machOFile segmentWithName:@"__OBJC"];
    moduleSection = [objcSegment sectionWithName:@"__module_info"];

    ptr = [moduleSection dataPointer];
    count = [moduleSection size] / sizeof(struct cd_objc_module);
    for (index = 0; index < count; index++, ptr++) {
        CDSegmentCommand *aSegment;
        CDOCModule *aModule;

        assert(ptr->size == sizeof(struct cd_objc_module)); // Because this is what we're assuming.
        aSegment = [machOFile segmentContainingAddress:ptr->symtab];

        aModule = [[CDOCModule alloc] init];
        [aModule setVersion:ptr->version];
        [aModule setName:[machOFile stringFromVMAddr:ptr->name]];
        [aModule setSymtab:[self processSymtab:ptr->symtab]];
        [modules addObject:aModule];

        [aModule release];
    }
}

- (CDOCSymtab *)processSymtab:(unsigned long)symtab;
{
    CDOCSymtab *aSymtab;

    // Huh?  The case of the struct 'cD_objc_symtab' doesn't matter?
    const struct cd_objc_symtab *ptr;
    const unsigned long *defs;
    int index, defIndex;
    NSMutableArray *classes, *categories;

    // TODO: Should we convert to pointer here or in caller?
    ptr = [machOFile pointerFromVMAddr:symtab segmentName:@"__OBJC"];
    if (ptr == NULL) {
        //NSLog(@"Skipping this symtab.");
        return nil;
    }

    aSymtab = [[[CDOCSymtab alloc] init] autorelease];
    // TODO (2003-12-08): I think it would be better just to let the symtab have mutable arrays
    classes = [[NSMutableArray alloc] init];
    categories = [[NSMutableArray alloc] init];

    //NSLog(@"%s, symtab: %p, ptr: %p", _cmd, symtab, ptr);
    //NSLog(@"sel_ref_cnt: %p, refs: %p, cls_def_count: %d, cat_def_count: %d", ptr->sel_ref_cnt, ptr->refs, ptr->cls_def_count, ptr->cat_def_count);

    //defs = &ptr->class_pointer;
    defs = (unsigned long *)(ptr + 1);
    defIndex = 0;

    if (ptr->cls_def_count > 0) {
        for (index = 0; index < ptr->cls_def_count; index++, defs++, defIndex++) {
            CDOCClass *aClass;

            //NSLog(@"defs[%d]: %p", index, *defs);
            aClass = [self processClassDefinition:*defs];
            [classes addObject:aClass];
        }
    }

    [aSymtab setClasses:[NSArray arrayWithArray:classes]];

    if (ptr->cat_def_count > 0) {
        //NSLog(@"%d categories:", ptr->cat_def_count);

        for (index = 0; index < ptr->cat_def_count; index++, defs++, defIndex++) {
            CDOCCategory *aCategory;

            //NSLog(@"defs[%d]: %p", index, *defs);
            aCategory = [self processCategoryDefinition:*defs];
            [categories addObject:aCategory];
        }
    }

    [aSymtab setCategories:[NSArray arrayWithArray:categories]];

    //NSLog(@"Classes:\n%@\n", [[classes arrayByMappingSelector:@selector(formattedString)] componentsJoinedByString:@"\n"]);

    [classes release];
    [categories release];

    return aSymtab;
}

- (CDOCClass *)processClassDefinition:(unsigned long)defRef;
{
    const struct cd_objc_class *classPtr;
    CDOCClass *aClass;
    int index;

    classPtr = [machOFile pointerFromVMAddr:defRef];

    aClass = [[[CDOCClass alloc] init] autorelease];
    [aClass setName:[machOFile stringFromVMAddr:classPtr->name]];
    [aClass setSuperClassName:[machOFile stringFromVMAddr:classPtr->super_class]];

    // Process ivars
    if (classPtr->ivars != 0) {
        const struct cd_objc_ivars *ivarsPtr;
        const struct cd_objc_ivar *ivarPtr;
        NSMutableArray *ivars;

        ivars = [[NSMutableArray alloc] init];
        ivarsPtr = [machOFile pointerFromVMAddr:classPtr->ivars];
        ivarPtr = (struct cd_objc_ivar *)(ivarsPtr + 1);

        for (index = 0; index < ivarsPtr->ivar_count; index++, ivarPtr++) {
            CDOCIvar *anIvar;

            anIvar = [[CDOCIvar alloc] initWithName:[machOFile stringFromVMAddr:ivarPtr->name]
                                       type:[machOFile stringFromVMAddr:ivarPtr->type]
                                       offset:ivarPtr->offset];
            [ivars addObject:anIvar];
            [anIvar release];
        }

        //[aClass setIvars:[ivars reversedArray]];
        [aClass setIvars:[NSArray arrayWithArray:ivars]];
        [ivars release];
    }

    // Process methods
    [aClass setInstanceMethods:[self processMethods:classPtr->methods]];

    // Process meta class
    {
        const struct cd_objc_class *metaClassPtr;

        metaClassPtr = [machOFile pointerFromVMAddr:classPtr->isa];
        //assert(metaClassPtr->info & CLS_CLASS);

        // Process class methods
        [aClass setClassMethods:[self processMethods:metaClassPtr->methods]];
    }

    // Process protocols
    [aClass addProtocolsFromArray:[self processProtocolList:classPtr->protocols]];

    return aClass;
}

- (NSArray *)processProtocolList:(unsigned long)protocolListAddr;
{
    const struct cd_objc_protocol_list *protocolList;
    const unsigned long *protocolPtrs;
    NSMutableArray *protocols;
    int index;

    protocols = [[[NSMutableArray alloc] init] autorelease];;

    if (protocolListAddr == 0)
        return protocols;

    protocolList = [machOFile pointerFromVMAddr:protocolListAddr];
    // Compiler doesn't like the double star cast.
    protocolPtrs = (void *)(protocolList + 1);
    //protocolPtrs = (unsigned long **)(protocolList + 1);
    for (index = 0; index < protocolList->count; index++, protocolPtrs++) {
        [protocols addObject:[self processProtocol:*protocolPtrs]];
    }

    return protocols;
}

- (CDOCProtocol *)processProtocol:(unsigned long)protocolAddr;
{
    const struct cd_objc_protocol *protocolPtr;
    CDOCProtocol *aProtocol;
    NSString *name;
    NSArray *protocols;

    protocolPtr = [machOFile pointerFromVMAddr:protocolAddr];

    name = [machOFile stringFromVMAddr:protocolPtr->protocol_name];
    protocols = [self processProtocolList:protocolPtr->protocol_list];

    aProtocol = [protocolsByName objectForKey:name];
    if (aProtocol == nil) {
        aProtocol = [[[CDOCProtocol alloc] init] autorelease];
        [aProtocol setName:name];

        [protocolsByName setObject:aProtocol forKey:name];
    }

    [aProtocol addProtocolsFromArray:protocols];
    if ([[aProtocol instanceMethods] count] == 0)
        [aProtocol setInstanceMethods:[self processProtocolMethods:protocolPtr->instance_methods]];

    if ([[aProtocol classMethods] count] == 0)
        [aProtocol setClassMethods:[self processProtocolMethods:protocolPtr->class_methods]];

    // TODO (2003-12-09): Maybe we should add any missing methods.  But then we'd lose the original order.

    return aProtocol;
}

- (NSArray *)processProtocolMethods:(unsigned long)methodsAddr;
{
    NSMutableArray *methods;
    const struct cd_objc_protocol_methods *methodsPtr;
    const struct cd_objc_protocol_method *methodPtr;
    int index;

    methods = [NSMutableArray array];
    if (methodsAddr == 0)
        return methods;

    methodsPtr = [machOFile pointerFromVMAddr:methodsAddr];
    methodPtr = (struct cd_objc_protocol_method *)(methodsPtr + 1);

    for (index = 0; index < methodsPtr->method_count; index++, methodPtr++) {
        CDOCMethod *aMethod;

        aMethod = [[CDOCMethod alloc] initWithName:[machOFile stringFromVMAddr:methodPtr->name]
                                      type:[machOFile stringFromVMAddr:methodPtr->types]
                                      imp:0];
        [methods addObject:aMethod];
        [aMethod release];
    }

    return [methods reversedArray];
}

- (NSArray *)processMethods:(unsigned long)methodsAddr;
{
    NSMutableArray *methods;
    const struct cd_objc_methods *methodsPtr;
    const struct cd_objc_method *methodPtr;
    int index;

    methods = [NSMutableArray array];
    if (methodsAddr == 0)
        return methods;

    methodsPtr = [machOFile pointerFromVMAddr:methodsAddr];
    methodPtr = (struct cd_objc_method *)(methodsPtr + 1);

    for (index = 0; index < methodsPtr->method_count; index++, methodPtr++) {
        CDOCMethod *aMethod;

        aMethod = [[CDOCMethod alloc] initWithName:[machOFile stringFromVMAddr:methodPtr->name]
                                      type:[machOFile stringFromVMAddr:methodPtr->types]
                                      imp:methodPtr->imp];
        [methods addObject:aMethod];
        [aMethod release];
    }

    return [methods reversedArray];
}

- (CDOCCategory *)processCategoryDefinition:(unsigned long)defRef;
{
    const struct cd_objc_category *categoryPtr;
    CDOCCategory *aCategory;

    categoryPtr = [machOFile pointerFromVMAddr:defRef];

    aCategory = [[[CDOCCategory alloc] init] autorelease];
    [aCategory setName:[machOFile stringFromVMAddr:categoryPtr->category_name]];
    [aCategory setClassName:[machOFile stringFromVMAddr:categoryPtr->class_name]];

    // Process methods
    [aCategory setInstanceMethods:[self processMethods:categoryPtr->methods]];
    [aCategory setClassMethods:[self processMethods:categoryPtr->class_methods]];

    // Process protocols
    [aCategory addProtocolsFromArray:[self processProtocolList:categoryPtr->protocols]];

    return aCategory;
}

// Protocol reference other protocols, so we can't try to create them
// in order.  So we create them lazily and just make sure we reference
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
