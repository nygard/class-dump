// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

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
@end

#pragma mark -

@implementation CDOCProtocol
{
    NSString *_name;
    NSMutableArray *_protocols;
    NSMutableArray *_classMethods;
    NSMutableArray *_instanceMethods;
    NSMutableArray *_optionalClassMethods;
    NSMutableArray *_optionalInstanceMethods;
    NSMutableArray *_properties;
    
    NSMutableSet *_adoptedProtocolNames;
}

- (id)init;
{
    if ((self = [super init])) {
        _name = nil;
        _protocols               = [[NSMutableArray alloc] init];
        _classMethods            = [[NSMutableArray alloc] init];
        _instanceMethods         = [[NSMutableArray alloc] init];
        _optionalClassMethods    = [[NSMutableArray alloc] init];
        _optionalInstanceMethods = [[NSMutableArray alloc] init];
        _properties              = [[NSMutableArray alloc] init];
        
        _adoptedProtocolNames    = [[NSMutableSet alloc] init];
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> name: %@, protocols: %ld, class methods: %ld, instance methods: %ld",
            NSStringFromClass([self class]), self, self.name, [self.protocols count], [self.classMethods count], [self.instanceMethods count]];
}

#pragma mark -

// This assumes that the protocol name doesn't change after it's been added to this.
- (void)addProtocol:(CDOCProtocol *)protocol;
{
    if ([_adoptedProtocolNames containsObject:protocol.name] == NO) {
        [_protocols addObject:protocol];
        [_adoptedProtocolNames addObject:protocol.name];
    }
}

- (void)removeProtocol:(CDOCProtocol *)protocol;
{
    [_adoptedProtocolNames removeObject:protocol.name];
    [_protocols removeObject:protocol];
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

- (void)addClassMethod:(CDOCMethod *)method;
{
    [_classMethods addObject:method];
}

- (void)addInstanceMethod:(CDOCMethod *)method;
{
    [_instanceMethods addObject:method];
}

- (void)addOptionalClassMethod:(CDOCMethod *)method;
{
    [_optionalClassMethods addObject:method];
}

- (void)addOptionalInstanceMethod:(CDOCMethod *)method;
{
    [_optionalInstanceMethods addObject:method];
}

- (void)addProperty:(CDOCProperty *)property;
{
    [_properties addObject:property];
}

- (BOOL)hasMethods;
{
    return [self.classMethods count] > 0 || [self.instanceMethods count] > 0 || [self.optionalClassMethods count] > 0 || [self.optionalInstanceMethods count] > 0;
}

- (void)registerTypesWithObject:(CDTypeController *)typeController phase:(NSUInteger)phase;
{
    [self registerTypesFromMethods:self.classMethods    withObject:typeController phase:phase];
    [self registerTypesFromMethods:self.instanceMethods withObject:typeController phase:phase];

    [self registerTypesFromMethods:self.optionalClassMethods    withObject:typeController phase:phase];
    [self registerTypesFromMethods:self.optionalInstanceMethods withObject:typeController phase:phase];
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
    return self.name;
}

- (NSComparisonResult)ascendingCompareByName:(CDOCProtocol *)other;
{
    return [self.sortableName compare:other.sortableName];
}

#pragma mark -

- (NSString *)methodSearchContext;
{
    NSMutableString *resultString = [NSMutableString string];

    [resultString appendFormat:@"@protocol %@", self.name];
    if ([self.protocols count] > 0)
        [resultString appendFormat:@" <%@>", self.protocolsString];

    return resultString;
}

- (void)recursivelyVisit:(CDVisitor *)visitor;
{
    if ([visitor.classDump shouldShowName:self.name] && visitor.shouldShowProtocolSection) {
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
    NSArray *methods = self.classMethods;
    if (visitor.classDump.shouldSortMethods)
        methods = [methods sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
    for (CDOCMethod *method in methods)
        [visitor visitClassMethod:method];

    methods = self.instanceMethods;
    if (visitor.classDump.shouldSortMethods)
        methods = [methods sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
    for (CDOCMethod *method in methods)
        [visitor visitInstanceMethod:method propertyState:propertyState];

    if ([self.optionalClassMethods count] > 0 || [self.optionalInstanceMethods count] > 0) {
        [visitor willVisitOptionalMethods];

        methods = self.optionalClassMethods;
        if (visitor.classDump.shouldSortMethods)
            methods = [methods sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
        for (CDOCMethod *method in methods)
            [visitor visitClassMethod:method];

        methods = self.optionalInstanceMethods;
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

#pragma mark -

- (void)mergeMethodsFromProtocol:(CDOCProtocol *)other;
{
    NSMutableDictionary *instanceMethodsByName         = [NSMutableDictionary dictionary];
    NSMutableDictionary *optionalInstanceMethodsByName = [NSMutableDictionary dictionary];
    NSMutableDictionary *classMethodsByName            = [NSMutableDictionary dictionary];
    NSMutableDictionary *optionalClassMethodsByName    = [NSMutableDictionary dictionary];
    
    for (CDOCMethod *method in _instanceMethods)
        instanceMethodsByName[method.name] = method;
    
    for (CDOCMethod *method in _optionalInstanceMethods)
        optionalInstanceMethodsByName[method.name] = method;
    
    for (CDOCMethod *method in _classMethods)
        classMethodsByName[method.name] = method;
    
    for (CDOCMethod *method in _optionalClassMethods)
        optionalClassMethodsByName[method.name] = method;
    
    // Instance methods
    for (CDOCMethod *method in other.instanceMethods) {
        CDOCMethod *m2 = instanceMethodsByName[method.name];
        if (m2 == nil) {
            // Add if it is not an optional instance method.
            if (optionalInstanceMethodsByName[method.name] == nil) {
                [self addInstanceMethod:method];
                instanceMethodsByName[method.name] = method;
            }
        }
    }
    
    for (CDOCMethod *method in other.optionalInstanceMethods) {
        CDOCMethod *m2 = optionalInstanceMethodsByName[method.name];
        if (m2 == nil) {
            m2 = instanceMethodsByName[method.name];
            if (m2 == nil) {
                [self addOptionalInstanceMethod:method];
                optionalInstanceMethodsByName[method.name] = method;
            } else {
                // Move to the optional instance methods.
                [self addOptionalInstanceMethod:m2];
                [_instanceMethods removeObject:m2];
                optionalInstanceMethodsByName[m2.name] = m2;
                [instanceMethodsByName removeObjectForKey:m2.name];
            }
        }
    }

    // Class methods
    for (CDOCMethod *method in other.classMethods) {
        CDOCMethod *m2 = classMethodsByName[method.name];
        if (m2 == nil) {
            // Add if it is not an optional class method.
            if (optionalClassMethodsByName[method.name] == nil) {
                [self addClassMethod:method];
                classMethodsByName[method.name] = method;
            }
        }
    }
    
    for (CDOCMethod *method in other.optionalClassMethods) {
        CDOCMethod *m2 = optionalClassMethodsByName[method.name];
        if (m2 == nil) {
            m2 = classMethodsByName[method.name];
            if (m2 == nil) {
                [self addOptionalClassMethod:method];
                optionalClassMethodsByName[method.name] = method;
            } else {
                // Move to the optional class methods.
                [self addOptionalClassMethod:m2];
                [_classMethods removeObject:m2];
                optionalClassMethodsByName[m2.name] = m2;
                [classMethodsByName removeObjectForKey:m2.name];
            }
        }
    }
}

- (void)mergePropertiesFromProtocol:(CDOCProtocol *)other;
{
    NSMutableDictionary *propertiesByName = [NSMutableDictionary dictionary];

    for (CDOCProperty *property in _properties)
        propertiesByName[property.name] = property;
    
    for (CDOCProperty *property in other.properties) {
        CDOCProperty *p2 = propertiesByName[property.name];
        if (p2 == nil) {
            [self addProperty:property];
            propertiesByName[property.name] = property;
        }
    }
}

@end
