// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDOCProtocol.h"

#import "CDClassDump.h"
#import "CDOCMethod.h"
#import "CDVisitor.h"
#import "CDOCProperty.h"
#import "CDMethodType.h"
#import "CDType.h"
#import "CDTypeController.h"
#import "CDVisitorPropertyState.h"

@interface CDOCProtocol ()
@property (nonatomic, readonly) NSString *sortableName;
- (void)recursivelyVisit:(CDVisitor *)visitor;
//- (void)visitProperties:(CDVisitor *)visitor;
@end

#pragma mark -

@implementation CDOCProtocol
{
    NSString *name;
    NSMutableArray *protocols;
    NSMutableArray *classMethods;
    NSMutableArray *instanceMethods;
    NSMutableArray *optionalClassMethods;
    NSMutableArray *optionalInstanceMethods;
    NSMutableArray *properties;
    
    NSMutableSet *adoptedProtocolNames;
}

- (id)init;
{
    if ((self = [super init])) {
        name = nil;
        protocols = [[NSMutableArray alloc] init];
        classMethods = [[NSMutableArray alloc] init];
        instanceMethods = [[NSMutableArray alloc] init];
        optionalClassMethods = [[NSMutableArray alloc] init];
        optionalInstanceMethods = [[NSMutableArray alloc] init];
        properties = [[NSMutableArray alloc] init];
        
        adoptedProtocolNames = [[NSMutableSet alloc] init];
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> name: %@, protocols: %ld, class methods: %ld, instance methods: %ld",
            NSStringFromClass([self class]), self, name, [protocols count], [classMethods count], [instanceMethods count]];
}

#pragma mark -

@synthesize name;
@synthesize protocols;

// This assumes that the protocol name doesn't change after it's been added to this.
- (void)addProtocol:(CDOCProtocol *)protocol;
{
    if ([adoptedProtocolNames containsObject:protocol.name] == NO) {
        [protocols addObject:protocol];
        [adoptedProtocolNames addObject:protocol.name];
    }
}

- (void)removeProtocol:(CDOCProtocol *)protocol;
{
    [adoptedProtocolNames removeObject:protocol.name];
    [protocols removeObject:protocol];
}

- (NSArray *)protocolNames;
{
    NSMutableArray *names = [[NSMutableArray alloc] init];
    [self.protocols enumerateObjectsUsingBlock:^(CDOCProtocol *protocol, NSUInteger index, BOOL *stop){
        if (protocol.name != nil)
            [names addObject:protocol.name];
    }];
    
    return [names copy];
}

- (NSString *)protocolsString;
{
    NSArray *names = self.protocolNames;
    if ([names count] == 0)
        return @"";

    return [names componentsJoinedByString:@", "];
}

- (NSArray *)classMethods;
{
    return classMethods;
}

- (void)addClassMethod:(CDOCMethod *)method;
{
    [classMethods addObject:method];
}

- (NSArray *)instanceMethods;
{
    return instanceMethods;
}

- (void)addInstanceMethod:(CDOCMethod *)method;
{
    [instanceMethods addObject:method];
}

- (NSArray *)optionalClassMethods;
{
    return optionalClassMethods;
}

- (void)addOptionalClassMethod:(CDOCMethod *)method;
{
    [optionalClassMethods addObject:method];
}

- (NSArray *)optionalInstanceMethods;
{
    return optionalInstanceMethods;
}

- (void)addOptionalInstanceMethod:(CDOCMethod *)method;
{
    [optionalInstanceMethods addObject:method];
}

@synthesize properties;

- (void)addProperty:(CDOCProperty *)property;
{
    [properties addObject:property];
}

- (BOOL)hasMethods;
{
    return [classMethods count] > 0 || [instanceMethods count] > 0 || [optionalClassMethods count] > 0 || [optionalInstanceMethods count] > 0;
}

- (void)registerTypesWithObject:(CDTypeController *)typeController phase:(NSUInteger)phase;
{
    [self registerTypesFromMethods:classMethods    withObject:typeController phase:phase];
    [self registerTypesFromMethods:instanceMethods withObject:typeController phase:phase];

    [self registerTypesFromMethods:optionalClassMethods    withObject:typeController phase:phase];
    [self registerTypesFromMethods:optionalInstanceMethods withObject:typeController phase:phase];
}

- (void)registerTypesFromMethods:(NSArray *)methods withObject:(CDTypeController *)typeController phase:(NSUInteger)phase;
{
    for (CDOCMethod *method in methods) {
        for (CDMethodType *methodType in method.parsedMethodTypes) {
            [methodType.type phase:phase registerTypesWithObject:typeController usedInMethod:YES];
        }
    }
}

#pragma mark - Sorting

- (NSString *)sortableName;
{
    return name;
}

- (NSComparisonResult)ascendingCompareByName:(CDOCProtocol *)otherProtocol;
{
    return [self.sortableName compare:otherProtocol.sortableName];
}

#pragma mark -

- (NSString *)methodSearchContext;
{
    NSMutableString *resultString = [NSMutableString string];

    [resultString appendFormat:@"@protocol %@", name];
    if ([protocols count] > 0)
        [resultString appendFormat:@" <%@>", self.protocolsString];

    return resultString;
}

- (void)recursivelyVisit:(CDVisitor *)visitor;
{
    if ([visitor.classDump shouldShowName:self.name]) {
        CDVisitorPropertyState *propertyState = [[CDVisitorPropertyState alloc] initWithProperties:self.properties];
        
        [visitor willVisitProtocol:self];
        
        //[aVisitor willVisitPropertiesOfProtocol:self];
        //[self visitProperties:aVisitor];
        //[aVisitor didVisitPropertiesOfProtocol:self];
        
        [self visitMethods:visitor propertyState:propertyState];
        
        // @optional properties will generate optional instance methods, and we'll emit @property in the @optional section.
        [visitor visitRemainingProperties:propertyState];
        
        [visitor didVisitProtocol:self];
    }
}

- (void)visitMethods:(CDVisitor *)visitor propertyState:(CDVisitorPropertyState *)propertyState;
{
    NSArray *methods = classMethods;
    if (visitor.classDump.shouldSortMethods)
        methods = [methods sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
    for (CDOCMethod *method in methods)
        [visitor visitClassMethod:method];

    methods = instanceMethods;
    if (visitor.classDump.shouldSortMethods)
        methods = [methods sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
    for (CDOCMethod *method in methods)
        [visitor visitInstanceMethod:method propertyState:propertyState];

    if ([optionalClassMethods count] > 0 || [optionalInstanceMethods count] > 0) {
        [visitor willVisitOptionalMethods];

        methods = optionalClassMethods;
        if (visitor.classDump.shouldSortMethods)
            methods = [methods sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
        for (CDOCMethod *method in methods)
            [visitor visitClassMethod:method];

        methods = optionalInstanceMethods;
        if (visitor.classDump.shouldSortMethods)
            methods = [methods sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
        for (CDOCMethod *method in methods)
            [visitor visitInstanceMethod:method propertyState:propertyState];

        [visitor didVisitOptionalMethods];
    }
}

#if 0
- (void)visitProperties:(CDVisitor *)visitor;
{
    NSArray *array = properties;
    if (visitor.classDump.shouldSortMethods)
        array = [array sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
    for (CDOCProperty *property in array)
        [visitor visitProperty:property];
}
#endif

@end
