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
    protocolsByVMAddr = [[NSMutableDictionary alloc] init];
    usedVMAddrs = [[NSMutableDictionary alloc] init];

    return self;
}

- (void)dealloc;
{
    [machOFile release];
    [modules release];
    [protocolsByVMAddr release];
    [usedVMAddrs release];

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
            //NSLog(@"aClass: %@", aClass);
            //NSLog(@"%@", [aClass formattedString]);
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
    CDOCClass *aClass;
    int index;

    classPtr = [machOFile pointerFromVMAddr:defRef];

    aClass = [[[CDOCClass alloc] init] autorelease];
    [aClass setName:[machOFile stringFromVMAddr:classPtr->name]];
    [aClass setSuperClassName:[machOFile stringFromVMAddr:classPtr->super_class]];

    // Process ivars
    NSLog(@"classPtr->ivars: %p", classPtr->ivars);
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

        [aClass setIvars:[ivars reversedArray]];
        [ivars release];
    }

    // Process methods
    NSLog(@"classPtr->methods: %p", classPtr->methods);
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
    NSLog(@"Protocols start (%@) ************************************************************", [aClass name]);
    [self processProtocolList:classPtr->protocols];
    NSLog(@"Protocols end (%@) ************************************************************", [aClass name]);

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

    //NSLog(@"protocolListAddr: %p", protocolListAddr);
    protocolList = [machOFile pointerFromVMAddr:protocolListAddr];
    // Compiler doesn't like the double star cast.
    protocolPtrs = (void *)(protocolList + 1);
    //protocolPtrs = (unsigned long **)(protocolList + 1);
    NSLog(@"%d protocols:", protocolList->count);
    for (index = 0; index < protocolList->count; index++, protocolPtrs++) {
        [protocols addObject:[self processProtocol:*protocolPtrs]];
    }

    return protocols;
}

- (CDOCProtocol *)processProtocol:(unsigned long)protocolAddr;
{
    const struct cd_objc_protocol *protocolPtr;
    CDOCProtocol *aProtocol;
    NSArray *methods;

    NSLog(@"%s, protocolAddr: %p", _cmd, protocolAddr);
    protocolPtr = [machOFile pointerFromVMAddr:protocolAddr];

    aProtocol = [[[CDOCProtocol alloc] init] autorelease];
    [aProtocol setName:[machOFile stringFromVMAddr:protocolPtr->protocol_name]];

    methods = [self processProtocolMethods:protocolPtr->instance_methods];
    [aProtocol setMethods:methods];

    // TODO (2003-12-09): Handle class methods

    //NSLog(@"protocolPtr->protocol_list: %p", protocolPtr->protocol_list);
    [aProtocol setProtocols:[self processProtocolList:protocolPtr->protocol_list]];

    //NSLog(@"aProtocol: %@", aProtocol);
    //NSLog(@"formatted protocol: %@", [aProtocol formattedString]);

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

- (void)processCategoryDefinition:(unsigned long)defRef;
{
    //const struct cd_objc_class *ptr;

    NSLog(@" > %s", _cmd);

    //ptr = [machOFile pointerFromVMAddr:defRef];
    //NSLog(@"isa: %p", ptr->isa);

    NSLog(@"<  %s", _cmd);
}

- (void)processProtocolSection;
{
    CDSegmentCommand *objcSegment;
    CDSection *protocolSection;
    unsigned long addr;
    CDOCProtocol *aProtocol;
    int count, index;

    NSLog(@" > %s", _cmd);

    objcSegment = [machOFile segmentWithName:@"__OBJC"];
    protocolSection = [objcSegment sectionWithName:@"__protocol"];
    NSLog(@"protocolSection: %@", protocolSection);

    addr = [protocolSection addr];

    NSLog(@"[protocolSection size]: %d", [protocolSection size]);
    NSLog(@"sizeof(struct cd_objc_protocol): %d", sizeof(struct cd_objc_protocol));
    count = [protocolSection size] / sizeof(struct cd_objc_protocol);
    NSLog(@"%d protocols in __protocol section", count);
    for (index = 0; index < count; index++, addr += sizeof(struct cd_objc_protocol)) {
        NSLog(@"%d: addr = %p", index, addr);
        aProtocol = [self processProtocol:addr];
        NSLog(@"%d: aProtocol: %@", index, aProtocol);
        [protocolsByVMAddr setObject:aProtocol forKey:[NSNumber numberWithLong:addr]];
    }

    NSLog(@"<  %s", _cmd);
}

- (CDOCProtocol *)protocolAtVMAddr:(unsigned long)protocolAddr;
{
    NSNumber *key;

    key = [NSNumber numberWithLong:protocolAddr];
    [usedVMAddrs setObject:@"Yes" forKey:key];

    return [protocolsByVMAddr objectForKey:key];
}

@end
