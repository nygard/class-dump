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
    protocolsByName = [[NSMutableDictionary alloc] init];
    protocolNames = [[NSMutableSet alloc] init];

    return self;
}

- (void)dealloc;
{
    [machOFile release];
    [modules release];
    [protocolsByName release];
    [protocolNames release];

    [super dealloc];
}

- (void)doSomething;
{
    CDOCProtocol *aProtocol;

    NSLog(@" > %s", _cmd);

    aProtocol = [self processProtocol:0xa0a1b6f0];
    NSLog(@"aProtocol: %@", aProtocol);

    aProtocol = [self processProtocol:0xa0a1b704];
    NSLog(@"aProtocol: %@", aProtocol);

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
    NSString *name;
    NSArray *protocols;

    //NSLog(@" > %s (%p)", _cmd, protocolAddr);
    //NSLog(@"%s, protocolAddr: %p", _cmd, protocolAddr);
    protocolPtr = [machOFile pointerFromVMAddr:protocolAddr];

    name = [machOFile stringFromVMAddr:protocolPtr->protocol_name];
    protocols = [self processProtocolList:protocolPtr->protocol_list];

    //NSLog(@"Processing protocol (%p) %@, adopts %@", protocolAddr, name, [[protocols arrayByMappingSelector:@selector(name)] description]);

    aProtocol = [protocolsByName objectForKey:name];
    if (aProtocol == nil) {
        aProtocol = [[[CDOCProtocol alloc] init] autorelease];
        [aProtocol setName:name];

        methods = [self processProtocolMethods:protocolPtr->instance_methods];
        [aProtocol setMethods:methods];

        // TODO (2003-12-09): Handle class methods

        //NSLog(@"protocolPtr->protocol_list: %p", protocolPtr->protocol_list);
        [aProtocol setProtocols:protocols];
        [protocolsByName setObject:aProtocol forKey:name];
    } else {
        int count, index;
        NSSet *previousProtocolNames;

        previousProtocolNames = [NSSet setWithArray:[[aProtocol protocols] arrayByMappingSelector:@selector(name)]];
        NSLog(@"=== protocol %@, previous protocol names: %@", name, [previousProtocolNames allObjects]);

        // Make sure all protocols adopted by this one are part of aProtocol
        count = [protocols count];
        for (index = 0; index < count; index++) {
            CDOCProtocol *thisProtocol;

            thisProtocol = [protocols objectAtIndex:index];
            NSLog(@"Checking for %@", [thisProtocol name]);
            if ([previousProtocolNames containsObject:[thisProtocol name]] == NO) {
                NSLog(@"Warning: Previous instance of this protocol doesn't adopt '%@' protocol that this instance does.", [thisProtocol name]);
            }
        }
    }

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

    NSLog(@"\n\n\n\n\n\n\n\n\n\n");
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
        //NSLog(@"%d: addr = %p", index, addr);
        aProtocol = [self processProtocol:addr];
        //NSLog(@"%d: aProtocol: %@", index, aProtocol);
    }

    {
        NSLog(@"unique protocols: %@", [protocolsByName allValues]);
        NSLog(@"\n\n\n\n\n\n\n\n\n\n");
        NSLog(@"protocols in order: \n%@",
              [[[protocolsByName allValues] arrayByMappingSelector:@selector(formattedString)] componentsJoinedByString:@"\n\n"]);
    }

    NSLog(@"<  %s", _cmd);
}

- (void)checkUnreferencedProtocols;
{
    NSLog(@" > %s", _cmd);
    NSLog(@"protocolNames: %@", protocolNames);
    NSLog(@"<  %s", _cmd);
}

@end
