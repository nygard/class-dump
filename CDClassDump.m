#import "CDClassDump.h"

#import <Foundation/Foundation.h>
#import "CDMachOFile.h"
#import "CDOCClass.h"
#import "CDOCIvar.h"
#import "CDOCMethod.h"
#import "CDOCModule.h"
#import "CDOCProtocol.h"
#import "CDOCSymtab.h"
#import "CDSection.h"
#import "CDSegmentCommand.h"
#import "NSArray-Extensions.h"

@implementation CDClassDump2

- (id)initWithMachOFile:(CDMachOFile *)aMachOFile;
{
    if ([super init] == nil)
        return nil;

    machOFile = [aMachOFile retain];
    modules = [[NSMutableArray alloc] init];

    return self;
}

- (void)dealloc;
{
    [machOFile release];
    [modules release];

    [super dealloc];
}

- (void)doSomething;
{
    CDSegmentCommand *segment;
    unsigned long goodVMAddr = 0xa2e3d960;
    unsigned long badVMAddr = 0xa2de2038;

    NSLog(@" > %s", _cmd);

    NSLog(@"good vmaddr: %p", goodVMAddr);
    segment = [machOFile segmentContainingAddress:goodVMAddr];
    NSLog(@"segment: %@", segment);

    NSLog(@"bad vmaddr: %p", badVMAddr);
    segment = [machOFile segmentContainingAddress:badVMAddr];
    NSLog(@"segment: %@", segment);

    NSLog(@" < %s", _cmd);
}

- (void)processModules;
{
    CDSegmentCommand *objcSegment;
    CDSection *moduleSection;
    const struct cd_objc_module *ptr;
    int count, index;

    NSLog(@" > %s", _cmd);

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
        NSLog(@"----------------------------------------------------------------------");
        [aModule setSymtab:[self processSymtab:ptr->symtab]];
        NSLog(@"aModule: %@", aModule);
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

    // class pointer: 0xa2df7fdc

    // TODO: Should we convert to pointer here or in caller?
    ptr = [machOFile pointerFromVMAddr:symtab segmentName:@"__OBJC"];
    if (ptr == NULL) {
        NSLog(@"Skipping this symtab.");
        return nil;
    }

    aSymtab = [[[CDOCSymtab alloc] init] autorelease];
    // TODO (2003-12-08): I think it would be better just to let the symtab have mutable arrays
    classes = [[NSMutableArray alloc] init];
    categories = [[NSMutableArray alloc] init];

    NSLog(@"%s, symtab: %p, ptr: %p", _cmd, symtab, ptr);
    NSLog(@"sel_ref_cnt: %p, refs: %p, cls_def_count: %d, cat_def_count: %d", ptr->sel_ref_cnt, ptr->refs, ptr->cls_def_count, ptr->cat_def_count);

    //defs = &ptr->class_pointer;
    defs = (unsigned long *)(ptr + 1);
    defIndex = 0;

    if (ptr->cls_def_count > 0) {
        NSLog(@"%d classes:", ptr->cls_def_count);

        for (index = 0; index < ptr->cls_def_count; index++, defs++, defIndex++) {
            CDOCClass *aClass;

            NSLog(@"defs[%d]: %p", index, *defs);
            aClass = [self processClassDefinition:*defs];
            NSLog(@"aClass: %@", aClass);
            NSLog(@"%@", [aClass formattedString]);
            [classes addObject:aClass];
        }
    }

    if (ptr->cat_def_count > 0) {
        NSLog(@"%d categories:", ptr->cat_def_count);
        //NSLog(@"Later.");
#if 1
        for (index = 0; index < ptr->cat_def_count; index++, defs++, defIndex++) {
            NSLog(@"defs[%d]: %p", index, *defs);
            [self processCategoryDefinition:*defs];
        }
#endif
    }

    [aSymtab setClasses:[NSArray arrayWithArray:classes]];

    [classes release];
    [categories release];

    return aSymtab;
}

- (CDOCClass *)processClassDefinition:(unsigned long)defRef;
{
    const struct cd_objc_class *classPtr;
    const struct cd_objc_ivars *ivarsPtr;
    const struct cd_objc_ivar *ivarPtr;
    const struct cd_objc_methods *methodsPtr;
    const struct cd_objc_method *methodPtr;
    CDOCClass *aClass;
    int index;

    classPtr = [machOFile pointerFromVMAddr:defRef];

    aClass = [[[CDOCClass alloc] init] autorelease];
    [aClass setName:[machOFile stringFromVMAddr:classPtr->name]];
    [aClass setSuperClassName:[machOFile stringFromVMAddr:classPtr->super_class]];

    // Process ivars
    NSLog(@"classPtr->ivars: %p", classPtr->ivars);
    if (classPtr->ivars != 0) {
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

        [aClass setIvars:[ivars reversedArray]];
        [ivars release];
    }

    // Process methods
    NSLog(@"classPtr->methods: %p", classPtr->methods);
    if (classPtr->methods != 0) {
        NSMutableArray *methods;

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
        [methods release];
    }

    // Process meta class
    {
        const struct cd_objc_class *metaClassPtr;

        metaClassPtr = [machOFile pointerFromVMAddr:classPtr->isa];
        //assert(metaClassPtr->info & CLS_CLASS);

        // Process class methods
        if (metaClassPtr->methods != 0) {
            NSMutableArray *methods;

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

            [methods release];
        }
    }

    // Process protocols
    if (classPtr->protocols != 0) {
        const struct cd_objc_protocol_list *protocolList;
        const struct cd_objc_protocol **protocolPtr;
        NSMutableArray *protocols;

        protocols = [[NSMutableArray alloc] init];

        protocolList = [machOFile pointerFromVMAddr:classPtr->protocols];
        // Compiler doesn't like the double star cast.
        protocolPtr = (void *)(protocolList + 1);
        //protocolPtr = (struct cd_objc_protocol **)(protocolList + 1);
        for (index = 0; index < protocolList->count; index++, protocolPtr++) {
            CDOCProtocol *aProtocol;

            aProtocol = [[CDOCProtocol alloc] init];
            // TODO (2003-12-08): Let's worry about protocols later.
            [aProtocol setName:[machOFile stringFromVMAddr:(*protocolPtr)->protocol_name]];
            [protocols addObject:aProtocol];
            [aProtocol release];
        }

        [protocols release];
    }

    return aClass;
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
