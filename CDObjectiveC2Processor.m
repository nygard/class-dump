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
#import "CDLCDynamicSymbolTable.h"
#import "CDLCSymbolTable.h"
#import "CDOCCategory.h"
#import "CDClassDump.h"
#import "CDRelocationInfo.h"
#import "CDSymbol.h"

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
    categories = [[NSMutableArray alloc] init];
    classesByAddress = [[NSMutableDictionary alloc] init];
    protocolsByName = [[NSMutableDictionary alloc] init];
    protocolsByAddress = [[NSMutableDictionary alloc] init];

    return self;
}

- (void)dealloc;
{
    [classes release];
    [categories release];
    [classesByAddress release];
    [protocolsByName release];
    [protocolsByAddress release];

    [super dealloc];
}

- (BOOL)hasObjectiveCData;
{
    return [[machOFile segmentWithName:@"__DATA"] sectionWithName:@"__objc_classlist"] != nil;
}

- (void)recursivelyVisit:(CDVisitor *)aVisitor;
{
    NSMutableArray *allClasses;
    NSArray *protocolNames;

    allClasses = [[NSMutableArray alloc] init];
    [allClasses addObjectsFromArray:classes];
    [allClasses addObjectsFromArray:categories];

    protocolNames = [[protocolsByName allKeys] sortedArrayUsingSelector:@selector(compare:)];

    [aVisitor willVisitObjectiveCProcessor:self];

    if ([protocolNames count] > 0 || [allClasses count] > 0) {
        [aVisitor visitObjectiveCProcessor:self];
    }

    for (NSString *protocolName in protocolNames) {
        [[protocolsByName objectForKey:protocolName] recursivelyVisit:aVisitor];
    }

    if ([[aVisitor classDump] shouldSortClassesByInheritance] == YES) {
        [allClasses sortTopologically];
    } else if ([[aVisitor classDump] shouldSortClasses] == YES) {
        [allClasses sortUsingSelector:@selector(ascendingCompareByName:)];
    }

    for (id aClassOrCategory in allClasses)
        [aClassOrCategory recursivelyVisit:aVisitor];

    [aVisitor didVisitObjectiveCProcessor:self];

    [allClasses release];
}

- (NSString *)externalClassNameForAddress:(uint64_t)address;
{
    CDRelocationInfo *rinfo;
    CDSymbol *symbol;

    // Not for NSCFArray (NSMutableArray), NSSimpleAttributeDictionaryEnumerator (NSEnumerator), NSSimpleAttributeDictionary (NSDictionary), etc.
    // It turns out NSMutableArray is in /System/Library/Frameworks/CoreFoundation.framework/Versions/A/CoreFoundation, so...
    // ... it's an undefined symbol, need to look it up.
    rinfo = [[machOFile dynamicSymbolTable] relocationEntryWithOffset:address - [[machOFile symbolTable] baseAddress]];
    //NSLog(@"rinfo: %@", rinfo);
    if (rinfo != nil) {
        NSString *prefix = @"_OBJC_CLASS_$_";
        NSString *str;

        symbol = [[[machOFile symbolTable] symbols] objectAtIndex:rinfo.symbolnum];
        //NSLog(@"symbol: %@", symbol);

        // Now we could use GET_LIBRARY_ORDINAL(), look up the the appropriate mach-o file (being sure to have loaded them even without -r),
        // look up the symbol in that mach-o file, get the address, look up the class based on that address, and finally get the class name
        // from that.

        // Or, we could be lazy and take advantage of the fact that the class name we're after is in the symbol name:
        str = [symbol name];
        if ([str hasPrefix:prefix]) {
            return [str substringFromIndex:[prefix length]];
        } else {
            NSLog(@"Warning: Unknown prefix on symbol name... %@", str);
            return str;
        }
    }

    // This is fine, they might really be root objects.  NSObject, NSProxy
    return nil;
}

- (void)process;
{
    [[machOFile symbolTable] loadSymbols];
    [[machOFile dynamicSymbolTable] loadSymbols];

    [self loadProtocols];
    //NSLog(@"protocolsByAddress (%u): %@", [[protocolsByAddress allKeys] count], protocolsByAddress);
    //NSLog(@"protocolsByName (%u): %@", [[protocolsByName allKeys] count], protocolsByName);
    //exit(99);
    // Load classes first, so we can get a dictionary of classes by address
    [self loadClasses];
#if 0
    for (NSNumber *key in [[classesByAddress allKeys] sortedArrayUsingSelector:@selector(compare:)])
        NSLog(@"%016lx -> %@", [key unsignedIntegerValue], [[classesByAddress objectForKey:key] name]);
#endif
    [self loadCategories];
}

- (void)loadProtocols;
{
    CDLCSegment *segment;
    CDSection *section;
    NSUInteger dataOffset;
    NSString *str;
    NSData *sectionData;
    CDDataCursor *cursor;

    segment = [machOFile segmentWithName:@"__DATA"];
    section = [segment sectionWithName:@"__objc_protolist"];
    sectionData = [section data];

    cursor = [[CDDataCursor alloc] initWithData:sectionData];
    while ([cursor isAtEnd] == NO) {
        uint64_t val;

        val = [cursor readLittleInt64];
        //NSLog(@"----------------------------------------");
        //NSLog(@"val: %16lx", val);
        //[machOFile logInfoForAddress:val];
        [self protocolAtAddress:val];
    }

    // Now unique the protocols by name and store in protocolsByName
    for (NSNumber *key in [[protocolsByAddress allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        CDOCProtocol *p1, *p2;

        p1 = [protocolsByAddress objectForKey:key];
        p2 = [protocolsByName objectForKey:[p1 name]];
        if (p2 == nil) {
            p2 = [[CDOCProtocol alloc] init];
            [p2 setName:[p1 name]];
            [protocolsByName setObject:p2 forKey:[p2 name]];
            // adopted protocols still not set, will want uniqued instances
            [p2 release];
        } else {
        }
    }

    //NSLog(@"protocolsByName: %@", protocolsByName);

    //NSLog(@"uniqued protocol names: %@", [[[protocolsByName allKeys] sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@", "]);

    // And finally fill in adopted protocols, instance and class methods
    for (NSNumber *key in [[protocolsByAddress allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        CDOCProtocol *p1, *uniqueProtocol;

        p1 = [protocolsByAddress objectForKey:key];
        uniqueProtocol = [protocolsByName objectForKey:[p1 name]];
        for (CDOCProtocol *p2 in [p1 protocols])
            [uniqueProtocol addProtocol:[protocolsByName objectForKey:[p2 name]]];

        if ([[uniqueProtocol classMethods] count] == 0) {
            for (CDOCMethod *method in [p1 classMethods])
                [uniqueProtocol addClassMethod:method];
        } else {
            NSParameterAssert([[uniqueProtocol classMethods] count] == [[p1 classMethods] count]);
        }

        if ([[uniqueProtocol instanceMethods] count] == 0) {
            for (CDOCMethod *method in [p1 instanceMethods])
                [uniqueProtocol addInstanceMethod:method];
        } else {
            NSParameterAssert([[uniqueProtocol instanceMethods] count] == [[p1 instanceMethods] count]);
        }
    }

    //NSLog(@"protocolsByName: %@", protocolsByName);
}

- (CDOCProtocol *)protocolAtAddress:(uint64_t)address;
{
    NSNumber *key;
    CDOCProtocol *protocol;

    if (address == 0)
        return nil;

    key = [NSNumber numberWithUnsignedInteger:address];
    protocol = [protocolsByAddress objectForKey:key];
    if (protocol == nil) {
        CDDataCursor *cursor;
        NSString *str;

        uint64_t v1, v2, v3, v4, v5, v6, v7, v8;

        protocol = [[[CDOCProtocol alloc] init] autorelease];
        [protocolsByAddress setObject:protocol forKey:key];

        cursor = [[CDDataCursor alloc] initWithData:[machOFile data]];
        [cursor setByteOrder:[machOFile byteOrder]];
        [cursor setOffset:[machOFile dataOffsetForAddress:address]];
        NSParameterAssert([cursor offset] != 0);

        //NSLog(@"offset: %lu", [cursor offset]);

        v1 = [cursor readInt64];
        v2 = [cursor readInt64]; // protocol name
        v3 = [cursor readInt64]; // adopted protocol list? NSURLProtocolClient
        v4 = [cursor readInt64]; // instance methods
        v5 = [cursor readInt64]; // class methods
        v6 = [cursor readInt64]; // optionalInstanceMethods
        v7 = [cursor readInt64]; // optionalClassMethods
        v8 = [cursor readInt64]; // instanceProperties
        //NSLog(@"----------------------------------------");
        //NSLog(@"%016lx %016lx %016lx %016lx", v1, v2, v3, v4);
        //NSLog(@"%016lx %016lx %016lx %016lx", v5, v6, v7, v8);
        //[machOFile logInfoForAddress:v1];
        //[machOFile logInfoForAddress:v2];
        //[machOFile logInfoForAddress:v4];
        //[machOFile logInfoForAddress:v5];
        //[machOFile logInfoForAddress:v6];
        //[machOFile logInfoForAddress:v7];
        //[machOFile logInfoForAddress:v8];

        str = [machOFile stringAtAddress:v2];
        [protocol setName:str];

        if (v3 != 0) {
            uint64_t count, index;

            [cursor setOffset:[machOFile dataOffsetForAddress:v3]];
            count = [cursor readInt64];
            for (index = 0; index < count; index++) {
                uint64_t val;
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

        for (CDOCMethod *method in [self loadMethodsAtAddress:v4]) {
            [protocol addInstanceMethod:method];
        }

        for (CDOCMethod *method in [self loadMethodsAtAddress:v5]) {
            [protocol addClassMethod:method];
        }

#if 0
        //NSLog(@"protocol= %@", protocol);
        NSParameterAssert(v1 == 0);
        //[machOFile logInfoForAddress:v3];
        //NSParameterAssert(v3 == 0);
        //NSParameterAssert(v5 == 0);
        NSParameterAssert(v6 == 0);
        NSParameterAssert(v7 == 0);
        NSParameterAssert(v8 == 0);
#endif

        [cursor release];
    }

    return protocol;
}

- (void)loadClasses;
{
    CDLCSegment *segment, *s2;
    NSUInteger dataOffset;
    NSString *str;
    CDSection *section;
    NSData *sectionData;
    CDDataCursor *cursor;

    //NSLog(@"machOFile: %@", machOFile);
    //NSLog(@"load commands: %@", [machOFile loadCommands]);

    segment = [machOFile segmentWithName:@"__DATA"];
    //NSLog(@"data segment offset: %lx", [segment fileoff]);
    //NSLog(@"data segment: %@", segment);
    //[segment writeSectionData];

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
        [classesByAddress setObject:aClass forKey:[NSNumber numberWithUnsignedInteger:val]];
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
}

- (void)loadCategories;
{
    CDLCSegment *segment;
    CDSection *section;
    NSUInteger dataOffset;
    NSString *str;
    NSData *sectionData;
    CDDataCursor *cursor;

    segment = [machOFile segmentWithName:@"__DATA"];
    section = [segment sectionWithName:@"__objc_catlist"];
    sectionData = [section data];

    cursor = [[CDDataCursor alloc] initWithData:sectionData];
    while ([cursor isAtEnd] == NO) {
        uint64_t val;
        CDOCCategory *category;

        val = [cursor readLittleInt64];
        //NSLog(@"----------------------------------------");
        //NSLog(@"val: %16lx", val);
        //[machOFile logInfoForAddress:val];
        category = [self loadCategoryAtAddress:val];
        //NSLog(@"loaded category: %@", category);
        if (category != nil)
            [categories addObject:category];
    }
}

- (CDOCCategory *)loadCategoryAtAddress:(uint64_t)address;
{
    CDDataCursor *cursor;
    NSString *str;
    CDOCCategory *category;

    uint64_t v1, v2, v3, v4, v5, v6, v7, v8;

    if (address == 0)
        return nil;

    cursor = [[CDDataCursor alloc] initWithData:[machOFile data]];
    [cursor setByteOrder:[machOFile byteOrder]];
    [cursor setOffset:[machOFile dataOffsetForAddress:address]];
    NSParameterAssert([cursor offset] != 0);

    v1 = [cursor readInt64]; // Category name
    v2 = [cursor readInt64]; // class
    v3 = [cursor readInt64]; // method list
    v4 = [cursor readInt64]; // TODO: One of these should be class methods...
    v5 = [cursor readInt64];
    v6 = [cursor readInt64];
    v7 = [cursor readInt64];
    v8 = [cursor readInt64];
    //NSLog(@"----------------------------------------");
    //NSLog(@"%016lx %016lx %016lx %016lx", v1, v2, v3, v4);
    //NSLog(@"%016lx %016lx %016lx %016lx", v5, v6, v7, v8);

    category = [[[CDOCCategory alloc] init] autorelease];
    str = [machOFile stringAtAddress:v1];
    [category setName:str];
    //NSLog(@"set name to %@", str);

    for (CDOCMethod *method in [self loadMethodsAtAddress:v3]) {
        [category addInstanceMethod:method];
    }

    for (CDOCMethod *method in [self loadMethodsAtAddress:v4]) {
        [category addClassMethod:method];
    }

    if (v2 == 0) {
        [category setClassName:[self externalClassNameForAddress:address + 8]];
    } else {
        CDOCClass *aClass;

        aClass = [classesByAddress objectForKey:[NSNumber numberWithUnsignedInteger:v2]];
        [category setClassName:[aClass name]];
        //NSLog(@"set class name to %@", [aClass name]);
    }

    return category;
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

    if (objc2Class.superclass == 0) {
        [aClass setSuperClassName:[self externalClassNameForAddress:address + 8]];
    } else {
        CDOCClass *sc;

        //NSLog(@"objc2Class.superclass of %@ is not 0", [aClass name]);
        //NSLog(@"Address of objc2Class.superclass should be... %016lx (%u)", address + 8, address + 8);
        //[machOFile logInfoForAddress:0x002cade8];
        //exit(99);
        //NSLog(@"superclass address: %016lx", objc2Class.superclass);
        sc = [self loadClassAtAddress:objc2Class.superclass];
        //NSLog(@"sc: %@", sc);
        //NSLog(@"sc name: %@", [sc name]);
        [aClass setSuperClassName:[sc name]];
    }

    {
        CDOCClass *metaclass;

        metaclass = [self loadMetaClassAtAddress:objc2Class.isa];
        //NSLog(@"metaclass [%016lx]: %@", objc2Class.isa, metaclass);
        //NSLog(@"metaclass name (%@) for class name (%@)", [metaclass name], [aClass name]);
        for (CDOCMethod *method in [metaclass classMethods])
            [aClass addClassMethod:method];
    }

    // Process protocols
    [aClass addProtocolsFromArray:[self uniquedProtocolListAtAddress:objc2ClassData.baseProtocols]];

    return aClass;
}

// This just gets the name and methods.
- (CDOCClass *)loadMetaClassAtAddress:(uint64_t)address;
{
    struct cd_objc2_class objc2Class;
    struct cd_objc2_class_ro_t objc2ClassData;
    CDDataCursor *cursor;
    NSString *str;
    CDOCClass *aClass;

    if (address == 0)
        return nil;

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
        [aClass addClassMethod:method];

    NSParameterAssert(objc2ClassData.ivars == 0);
    //[aClass setIvars:[self loadIvarsAtAddress:objc2ClassData.ivars]];

    [cursor release];

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

// Returns list of uniqued protocols.
- (NSArray *)uniquedProtocolListAtAddress:(uint64_t)address;
{
    NSMutableArray *protocols;

    protocols = [[[NSMutableArray alloc] init] autorelease];;

    if (address != 0) {
        CDDataCursor *cursor;
        uint64_t count, index;

        cursor = [[CDDataCursor alloc] initWithData:[machOFile data]];
        [cursor setByteOrder:[machOFile byteOrder]];
        [cursor setOffset:[machOFile dataOffsetForAddress:address]];
        //NSLog(@"offset: %lu", [cursor offset]);
        count = [cursor readInt64];

        for (index = 0; index < count; index++) {
            uint64_t val;
            CDOCProtocol *protocol, *uniqueProtocol;

            val = [cursor readInt64];
            protocol = [protocolsByAddress objectForKey:[NSNumber numberWithUnsignedInteger:val]];
            //NSLog(@"%3d protocol @ %08x: %@", index, val, [protocol name]);
            if (protocol != nil) {
                uniqueProtocol = [protocolsByName objectForKey:[protocol name]];
                if (uniqueProtocol != nil)
                    [protocols addObject:uniqueProtocol];
            }
        }

        [cursor release];
    }

    return protocols;
}

@end
