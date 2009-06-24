//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2009 Steve Nygard.  All rights reserved.

#import "CDObjectiveC2Processor.h"

#import "CDMachOFile.h"
#import "CDSection.h"
#import "CDLCSegment.h"
#import "CDDataCursor.h"
#import "CDOCClass.h"
#import "CDOCMethod.h"
#import "CDVisitor.h"
#import "CDOCIvar.h"
#import "NSArray-Extensions.h"

struct cd_objc2_class {
    uint64_t isa;
    uint64_t superclass;
    uint64_t cache;
    uint64_t vtable;
    uint64_t data; // points to class_ro_t
    uint64_t reserved1;
    uint64_t reserved2;
    uint64_t reserved3;
};

struct cd_objc2_class_ro_t {
    uint32_t flags;
    uint32_t instanceStart;
    uint32_t instanceSize;
    uint32_t reserved;
    uint64_t ivarLayout;
    uint64_t name;
    uint64_t baseMethods;
    uint64_t baseProtocols;
    uint64_t ivars;
    uint64_t weakIvarLayout;
    uint64_t baseProperties;
};

struct cd_objc2_list_header {
    uint32_t entsize;
    uint32_t count;
};

struct cd_objc2_method {
    uint64_t name;
    uint64_t types;
    uint64_t imp;
};

struct cd_objc2_ivar {
    uint64_t offset;
    uint64_t name;
    uint64_t type;
    uint32_t alignment;
    uint32_t size;
};

struct cd_objc2_iamge_info {
    uint32_t version;
    uint32_t flags;
};

@implementation CDObjectiveC2Processor

- (id)initWithMachOFile:(CDMachOFile *)aMachOFile;
{
    if ([super initWithMachOFile:aMachOFile] == nil)
        return nil;

    classes = [[NSMutableArray alloc] init];

    return self;
}

- (void)dealloc;
{
    [classes release];

    [super dealloc];
}

- (BOOL)hasObjectiveCData;
{
    return [[machOFile segmentWithName:@"__DATA"] sectionWithName:@"__objc_classlist"] != nil;
}

- (void)recursivelyVisit:(CDVisitor *)aVisitor;
{
    NSLog(@" > %s", _cmd);

    [aVisitor willVisitObjectiveCProcessor:self];
    [aVisitor visitObjectiveCProcessor:self];

    for (CDOCClass *aClass in classes)
        [aClass recursivelyVisit:aVisitor];

    [aVisitor didVisitObjectiveCProcessor:self];

    NSLog(@"<  %s", _cmd);
}

- (void)process;
{
    CDLCSegment *segment, *s2;
    NSUInteger dataOffset;
    NSString *str;
    CDSection *section;
    NSData *sectionData;
    CDDataCursor *cursor;

    NSLog(@" > %s", _cmd);

    //NSLog(@"machOFile: %@", machOFile);
    //NSLog(@"load commands: %@", [machOFile loadCommands]);

    segment = [machOFile segmentWithName:@"__DATA"];
    //NSLog(@"data segment offset: %lx", [segment fileoff]);
    //NSLog(@"data segment: %@", segment);
    [segment writeSectionData];

    section = [segment sectionWithName:@"__objc_classlist"];
    //NSLog(@"section: %@", section);

    sectionData = [section data];
    cursor = [[CDDataCursor alloc] initWithData:sectionData];
    while ([cursor isAtEnd] == NO) {
        uint64_t val;
        CDOCClass *aClass;

        val = [cursor readLittleInt64];
        //NSLog(@"----------------------------------------");
        //NSLog(@"val: %16lx", val);

        aClass = [self loadClassAtAddress:val];
        [classes addObject:aClass];
    }
    [cursor release];
#if 0
    s2 = [machOFile segmentContainingAddress:0x2cab60];
    NSLog(@"s2 contains 0x2cab60: %@", s2);

    dataOffset = [machOFile dataOffsetForAddress:0x2cab60];
    NSLog(@"dataOffset: %lx (%lu)", dataOffset, dataOffset);

    str = [machOFile stringAtAddress:0x2cac00];
    NSLog(@"str: %@", str);
#endif

    NSLog(@"<  %s", _cmd);
}

- (CDOCClass *)loadClassAtAddress:(uint64_t)address;
{
    struct cd_objc2_class objc2Class;
    struct cd_objc2_class_ro_t objc2ClassData;
    CDDataCursor *cursor;
    NSString *str;
    CDOCClass *aClass;

    if (address == 0)
        return nil;

    //NSLog(@"%s, address=%016lx", _cmd, address);

    cursor = [[CDDataCursor alloc] initWithData:[machOFile data]];
    [cursor setByteOrder:[machOFile byteOrder]];
    [cursor setOffset:[machOFile dataOffsetForAddress:address]];
    NSParameterAssert([cursor offset] != 0);

    objc2Class.isa = [cursor readInt64];
    objc2Class.superclass = [cursor readInt64];
    objc2Class.cache = [cursor readInt64];
    objc2Class.vtable = [cursor readInt64];
    objc2Class.data = [cursor readInt64];
    objc2Class.reserved1 = [cursor readInt64];
    objc2Class.reserved2 = [cursor readInt64];
    objc2Class.reserved3 = [cursor readInt64];
    //NSLog(@"%016lx %016lx %016lx %016lx", objc2Class.isa, objc2Class.superclass, objc2Class.cache, objc2Class.vtable);
    //NSLog(@"%016lx %016lx %016lx %016lx", objc2Class.data, objc2Class.reserved1, objc2Class.reserved2, objc2Class.reserved3);

    NSParameterAssert(objc2Class.data != 0);
    [cursor setOffset:[machOFile dataOffsetForAddress:objc2Class.data]];
    objc2ClassData.flags = [cursor readInt32];
    objc2ClassData.instanceStart = [cursor readInt32];
    objc2ClassData.instanceSize = [cursor readInt32];
    objc2ClassData.reserved = [cursor readInt32];

    objc2ClassData.ivarLayout = [cursor readInt64];
    objc2ClassData.name = [cursor readInt64];
    objc2ClassData.baseMethods = [cursor readInt64];
    objc2ClassData.baseProtocols = [cursor readInt64];
    objc2ClassData.ivars = [cursor readInt64];
    objc2ClassData.weakIvarLayout = [cursor readInt64];
    objc2ClassData.baseProperties = [cursor readInt64];

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
#if 0
        NSLog(@"isa: %016lx, data offset: %lu", objc2Class.isa, [machOFile dataOffsetForAddress:0x2ca960]);
        NSLog(@"***");
        [machOFile logInfoForAddress:address];
        NSLog(@"***");

        [machOFile logInfoForAddress:objc2Class.isa];
        [machOFile logInfoForAddress:objc2Class.superclass];
        [machOFile logInfoForAddress:objc2Class.cache];
        [machOFile logInfoForAddress:objc2Class.vtable];
        [machOFile logInfoForAddress:objc2Class.data];
        [machOFile logInfoForAddress:objc2Class.reserved1];
        [machOFile logInfoForAddress:objc2Class.reserved2];
        [machOFile logInfoForAddress:objc2Class.reserved3];

        [machOFile logInfoForAddress:0x2ca960];
        [machOFile logInfoForAddress:0x2ca9a0];
#endif

        {
            CDOCClass *sc;

            //NSLog(@"superclass address: %016lx", objc2Class.superclass);
            sc = [self loadClassAtAddress:objc2Class.superclass];
            //NSLog(@"sc: %@", sc);
            //NSLog(@"sc name: %@", [sc name]);
            [aClass setSuperClassName:[sc name]];
        }
        //exit(99);
    }

    return aClass;
}

- (NSArray *)loadMethodsAtAddress:(uint64_t)address;
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
        NSParameterAssert(listHeader.entsize == 24);

        for (index = 0; index < listHeader.count; index++) {
            struct cd_objc2_method objc2Method;
            NSString *name, *types;
            CDOCMethod *method;

            objc2Method.name = [cursor readInt64];
            objc2Method.types = [cursor readInt64];
            objc2Method.imp = [cursor readInt64];
            name = [machOFile stringAtAddress:objc2Method.name];
            types = [machOFile stringAtAddress:objc2Method.types];

            //NSLog(@"%3u: %016lx %016lx %016lx", index, objc2Method.name, objc2Method.types, objc2Method.imp);
            //NSLog(@"name: %@", name);
            //NSLog(@"types: %@", types);

            method = [[CDOCMethod alloc] initWithName:name type:types imp:objc2Method.imp];
            [methods addObject:method];
            [method release];
        }
    }

    return [methods reversedArray];
}

- (NSArray *)loadIvarsAtAddress:(uint64_t)address;
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
        NSParameterAssert(listHeader.entsize == 32);

        for (index = 0; index < listHeader.count; index++) {
            struct cd_objc2_ivar objc2Ivar;
            NSString *name, *type;
            CDOCIvar *ivar;

            objc2Ivar.offset = [cursor readInt64];
            objc2Ivar.name = [cursor readInt64];
            objc2Ivar.type = [cursor readInt64];
            objc2Ivar.alignment = [cursor readInt32];
            objc2Ivar.size = [cursor readInt32];

            name = [machOFile stringAtAddress:objc2Ivar.name];
            type = [machOFile stringAtAddress:objc2Ivar.type];

            //NSLog(@"%3u: %016lx %016lx %016lx", index, objc2Method.name, objc2Method.types, objc2Method.imp);
            //NSLog(@"name: %@", name);
            //NSLog(@"types: %@", types);

            ivar = [[CDOCIvar alloc] initWithName:name type:type offset:objc2Ivar.offset];
            [ivars addObject:ivar];
            [ivar release];
        }
    }

    return ivars;
}

@end
