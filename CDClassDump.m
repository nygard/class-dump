#import "CDClassDump.h"

#import <Foundation/Foundation.h>
#import "CDMachOFile.h"
#import "CDOCClass.h"
#import "CDOCIvar.h"
#import "CDOCMethod.h"
#import "CDOCModule.h"
#import "CDOCProtocol.h"
#import "CDSection.h"
#import "CDSegmentCommand.h"
#import "NSArray-Extensions.h"

@implementation CDClassDump2

- (id)initWithMachOFile:(CDMachOFile *)aMachOFile;
{
    if ([super init] == nil)
        return nil;

    machOFile = [aMachOFile retain];

    return self;
}

- (void)dealloc;
{
    [machOFile release];
    [super dealloc];
}

- (void)doSomething;
{
    CDSegmentCommand *objectiveCSegment, *aSegment;

    NSLog(@" > %s", _cmd);

    objectiveCSegment = [machOFile segmentWithName:@"__OBJC"];
    NSLog(@"objectiveCSegment: %@", objectiveCSegment);
    NSLog(@"\n\n\n");

    aSegment = [machOFile segmentContainingAddress:0x93241e08];
    NSLog(@"aSegment: %@", aSegment);

    //NSLog(@"the pointer: %d", [machOFile pointerFromVMAddr:0x93241e08]);
    NSLog(@"the pointer: '%s'", [machOFile pointerFromVMAddr:0x93241e08]);

    NSLog(@"<  %s", _cmd);
}

- (void)processModules;
{
    CDSegmentCommand *objcSegment;
    CDSection *moduleSection;
    const struct cd_objc_module *ptr;
    int count, index;

    NSLog(@" > %s", _cmd);

    objcSegment = [machOFile segmentWithName:@"__OBJC"];
    NSLog(@"objcSegment: %@", objcSegment);

    moduleSection = [objcSegment sectionWithName:@"__module_info"];
    NSLog(@"moduleSection: %@", moduleSection);

    ptr = [moduleSection dataPointer];
    count = [moduleSection size] / sizeof(struct cd_objc_module);
    for (index = 0; index < count; index++, ptr++) {
        CDSegmentCommand *aSegment;
        CDOCModule *aModule;

        assert(ptr->size == sizeof(struct cd_objc_module)); // Because this is what we're assuming.
        NSLog(@"symtab: %p", ptr->symtab);
        aSegment = [machOFile segmentContainingAddress:ptr->symtab];
        NSLog(@"[machOFile segmentContainingAddress:ptr->symtab]: %@", aSegment);
#if 1
        aModule = [[CDOCModule alloc] init];
        [aModule setVersion:ptr->version];
        [aModule setName:[machOFile stringFromVMAddr:ptr->name]];
        [aModule setSymtab:ptr->symtab];
        NSLog(@"aModule: %@", aModule);
        [self processSymtab:ptr->symtab];
        [aModule release];
#endif
        break;
    }

    NSLog(@"<  %s", _cmd);
}

- (void)processSymtab:(unsigned long)symtab;
{
    // Huh?  The case of the struct 'cD_objc_symtab' doesn't matter?
    const struct cd_objc_symtab *ptr;
    const unsigned long *defs;
    int index, defIndex;

    NSLog(@" > %s", _cmd);

    // class pointer: 0xa2df7fdc

    // TODO: Should we convert to pointer here or in caller?
    ptr = [machOFile pointerFromVMAddr:symtab];
    NSLog(@"sel_ref_cnt: %p, refs: %p, cls_def_count: %d, cat_def_count: %d", ptr->sel_ref_cnt, ptr->refs, ptr->cls_def_count, ptr->cat_def_count);

    //defs = &ptr->class_pointer;
    defs = (unsigned long *)(ptr + 1);

    NSLog(@"Classes:");
    defIndex = 0;
    for (index = 0; index < ptr->cls_def_count; index++, defs++, defIndex++) {
        NSLog(@"defs[%d]: %p", index, *defs);
        [self processClassDefinition:*defs];
    }

    NSLog(@"Categories:");
    for (index = 0; index < ptr->cat_def_count; index++, defs++, defIndex++) {
        NSLog(@"defs[%d]: %p", index, *defs);
        [self processCategoryDefinition:*defs];
    }

    NSLog(@"<  %s", _cmd);
}

- (void)processClassDefinition:(unsigned long)defRef;
{
    const struct cd_objc_class *classPtr;
    const struct cd_objc_ivars *ivarsPtr;
    const struct cd_objc_ivar *ivarPtr;
    const struct cd_objc_methods *methodsPtr;
    const struct cd_objc_method *methodPtr;
    CDOCClass *aClass;
    int index;
    NSMutableArray *ivars, *methods;

    NSLog(@" > %s", _cmd);

    classPtr = [machOFile pointerFromVMAddr:defRef];
    NSLog(@"isa: %p", classPtr->isa);

    aClass = [[CDOCClass alloc] init];
    [aClass setName:[machOFile stringFromVMAddr:classPtr->name]];
    [aClass setSuperClassName:[machOFile stringFromVMAddr:classPtr->super_class]];
    NSLog(@"aClass: %@", aClass);

    // Process ivars
    ivars = [[NSMutableArray alloc] init];
    ivarsPtr = [machOFile pointerFromVMAddr:classPtr->ivars];
    NSLog(@"ivar count: %d", ivarsPtr->ivar_count);

    ivarPtr = (struct cd_objc_ivar *)(ivarsPtr + 1);
    for (index = 0; index < ivarsPtr->ivar_count; index++, ivarPtr++) {
        CDOCIvar *anIvar;

        anIvar = [[CDOCIvar alloc] initWithName:[machOFile stringFromVMAddr:ivarPtr->name]
                                   type:[machOFile stringFromVMAddr:ivarPtr->type]
                                   offset:ivarPtr->offset];
        [ivars addObject:anIvar];
        [anIvar release];
    }

    [aClass setIvars:[ivars reversedArray]];
    NSLog(@"ivars: %@", [aClass ivars]);
    [ivars release];

    // Process methods
    methods = [[NSMutableArray alloc] init];
    methodsPtr = [machOFile pointerFromVMAddr:classPtr->methods];
    methodPtr = (struct cd_objc_method *)(methodsPtr + 1);
    for (index = 0; index < methodsPtr->method_count; index++, methodPtr++) {
        CDOCMethod *aMethod;

        aMethod = [[CDOCMethod alloc] initWithName:[machOFile stringFromVMAddr:methodPtr->name]
                                          type:[machOFile stringFromVMAddr:methodPtr->types]
                                          imp:methodPtr->imp];
        [methods addObject:aMethod];
        [aMethod release];
    }

    [aClass setInstanceMethods:[methods reversedArray]];
    NSLog(@"instance methods: %@", [aClass instanceMethods]);
    [methods release];

    // Process meta class
    {
        const struct cd_objc_class *metaClassPtr;

        metaClassPtr = [machOFile pointerFromVMAddr:classPtr->isa];
        //assert(metaClassPtr->info & CLS_CLASS);

        // Process class methods
        if (metaClassPtr->methods != 0) {
            methods = [[NSMutableArray alloc] init];

            methodsPtr = [machOFile pointerFromVMAddr:metaClassPtr->methods];
            methodPtr = (struct cd_objc_method *)(methodsPtr + 1);
            for (index = 0; index < methodsPtr->method_count; index++, methodPtr++) {
                CDOCMethod *aMethod;

                aMethod = [[CDOCMethod alloc] initWithName:[machOFile stringFromVMAddr:methodPtr->name]
                                              type:[machOFile stringFromVMAddr:methodPtr->types]
                                              imp:methodPtr->imp];
                [methods addObject:aMethod];
                [aMethod release];
            }

            [aClass setClassMethods:[methods reversedArray]];
            NSLog(@"class methods: %@", [aClass classMethods]);

            [methods release];
        }
    }

    // Process protocols
    NSLog(@"protocol addr: %p", classPtr->protocols);
    if (classPtr->protocols != 0) {
        const struct cd_objc_protocol_list *protocolList;
        const struct cd_objc_protocol **protocolPtr;
        NSMutableArray *protocols;

        protocols = [[NSMutableArray alloc] init];

        protocolList = [machOFile pointerFromVMAddr:classPtr->protocols];
        // Compiler doesn't like the double star cast.
        protocolPtr = (void *)(protocolList + 1);
        //protocolPtr = (struct cd_objc_protocol **)(protocolList + 1);
        NSLog(@"protocol count: %d", protocolList->count);
        for (index = 0; index < protocolList->count; index++, protocolPtr++) {
            CDOCProtocol *aProtocol;

            aProtocol = [[CDOCProtocol alloc] init];
            NSLog(@"(*protocolPtr)->protocol_name: 0x%08x", (*protocolPtr)->protocol_name);
            [aProtocol setName:[machOFile stringFromVMAddr:(*protocolPtr)->protocol_name]];
            NSLog(@"aProtocol: %@", aProtocol);
            [protocols addObject:aProtocol];
            [aProtocol release];
        }

        NSLog(@"protocols: %@", protocols);
        [protocols release];
    }

    [aClass release];

    NSLog(@"<  %s", _cmd);
}

- (void)processCategoryDefinition:(unsigned long)defRef;
{
    //const struct cd_objc_class *ptr;

    NSLog(@" > %s", _cmd);

    //ptr = [machOFile pointerFromVMAddr:defRef];
    //NSLog(@"isa: %p", ptr->isa);

    NSLog(@"<  %s", _cmd);
}

@end
