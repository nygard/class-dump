// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDOCProtocol.h"

#import "NSArray-Extensions.h"
#import "NSError-CDExtensions.h"
#import "CDClassDump.h"
#import "CDOCMethod.h"
#import "CDOCSymtab.h"
#import "CDSymbolReferences.h"
#import "CDTypeParser.h"
#import "CDVisitor.h"
#import "CDOCProperty.h"
#import "CDMethodType.h"
#import "CDType.h"
#import "CDTypeController.h"
#import "CDVisitorPropertyState.h"

@implementation CDOCProtocol

- (id)init;
{
    if ([super init] == nil)
        return nil;

    name = nil;
    protocols = [[NSMutableArray alloc] init];
    classMethods = [[NSMutableArray alloc] init];
    instanceMethods = [[NSMutableArray alloc] init];
    optionalClassMethods = [[NSMutableArray alloc] init];
    optionalInstanceMethods = [[NSMutableArray alloc] init];
    properties = [[NSMutableArray alloc] init];

    adoptedProtocolNames = [[NSMutableSet alloc] init];

    return self;
}

- (void)dealloc;
{
    [name release];
    [protocols release];
    [classMethods release];
    [instanceMethods release];
    [optionalClassMethods release];
    [optionalInstanceMethods release];
    [properties release];

    [adoptedProtocolNames release];

    [super dealloc];
}

- (NSString *)name;
{
    return name;
}

- (void)setName:(NSString *)newName;
{
    if (newName == name)
        return;

    [name release];
    name = [newName retain];
}

- (NSArray *)protocols;
{
    return protocols;
}

// This assumes that the protocol name doesn't change after it's been added to this.
- (void)addProtocol:(CDOCProtocol *)aProtocol;
{
    if ([adoptedProtocolNames containsObject:[aProtocol name]] == NO) {
        [protocols addObject:aProtocol];
        [adoptedProtocolNames addObject:[aProtocol name]];
    }
}

- (void)removeProtocol:(CDOCProtocol *)aProtocol;
{
    [adoptedProtocolNames removeObject:[aProtocol name]];
    [protocols removeObject:aProtocol];
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

- (NSArray *)properties;
{
    return properties;
}

- (void)addProperty:(CDOCProperty *)property;
{
    [properties addObject:property];
}

- (BOOL)hasMethods;
{
    return [classMethods count] > 0 || [instanceMethods count] > 0 || [optionalClassMethods count] > 0 || [optionalInstanceMethods count] > 0;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> name: %@, protocols: %d, class methods: %d, instance methods: %d",
                     NSStringFromClass([self class]), self, name, [protocols count], [classMethods count], [instanceMethods count]];
}

- (void)registerTypesWithObject:(CDTypeController *)typeController phase:(NSUInteger)phase;
{
    [self registerTypesFromMethods:classMethods withObject:typeController phase:phase];
    [self registerTypesFromMethods:instanceMethods withObject:typeController phase:phase];

    [self registerTypesFromMethods:optionalClassMethods withObject:typeController phase:phase];
    [self registerTypesFromMethods:optionalInstanceMethods withObject:typeController phase:phase];
}

- (void)registerTypesFromMethods:(NSArray *)methods withObject:(CDTypeController *)typeController phase:(NSUInteger)phase;
{
    for (CDOCMethod *method in methods) {
        for (CDMethodType *methodType in [method parsedMethodTypes]) {
            [[methodType type] phase:phase registerTypesWithObject:typeController usedInMethod:YES];
        }
    }
}

- (NSString *)sortableName;
{
    return name;
}

- (NSComparisonResult)ascendingCompareByName:(CDOCProtocol *)otherProtocol;
{
    return [[self sortableName] compare:[otherProtocol sortableName]];
}

- (NSString *)findTag:(CDSymbolReferences *)symbolReferences;
{
    NSMutableString *resultString = [NSMutableString string];

    [resultString appendFormat:@"@protocol %@", name];
    if ([protocols count] > 0)
        [resultString appendFormat:@" <%@>", [[protocols arrayByMappingSelector:@selector(name)] componentsJoinedByString:@", "]];

    return resultString;
}

- (void)recursivelyVisit:(CDVisitor *)aVisitor;
{
    CDVisitorPropertyState *propertyState;

    if ([[aVisitor classDump] shouldMatchRegex] && [[aVisitor classDump] regexMatchesString:[self name]] == NO)
        return;

    // Wonderful.  Need to typecast because there's also -[NSHTTPCookie initWithProperties:] that takes a dictionary.
    propertyState = [(CDVisitorPropertyState *)[CDVisitorPropertyState alloc] initWithProperties:[self properties]];

    [aVisitor willVisitProtocol:self];

    //[aVisitor willVisitPropertiesOfProtocol:self];
    //[self visitProperties:aVisitor];
    //[aVisitor didVisitPropertiesOfProtocol:self];

    [self visitMethods:aVisitor propertyState:propertyState];

    // This shouldn't happen for protocols.  @optional properties will generate optional instance methods, and we'll emit @property in the @optional section.
    // BTW, otool doesn't show optional methods.
    [aVisitor visitRemainingProperties:propertyState];

    [aVisitor didVisitProtocol:self];

    [propertyState release];
}

- (void)visitMethods:(CDVisitor *)aVisitor propertyState:(CDVisitorPropertyState *)propertyState;
{
    NSArray *methods;

    methods = classMethods;
    if ([[aVisitor classDump] shouldSortMethods])
        methods = [methods sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
    for (CDOCMethod *method in methods)
        [aVisitor visitClassMethod:method];

    methods = instanceMethods;
    if ([[aVisitor classDump] shouldSortMethods])
        methods = [methods sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
    for (CDOCMethod *method in methods)
        [aVisitor visitInstanceMethod:method propertyState:propertyState];

    if ([optionalClassMethods count] > 0 || [optionalInstanceMethods count] > 0) {
        [aVisitor willVisitOptionalMethods];

        methods = optionalClassMethods;
        if ([[aVisitor classDump] shouldSortMethods])
            methods = [methods sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
        for (CDOCMethod *method in methods)
            [aVisitor visitClassMethod:method];

        methods = optionalInstanceMethods;
        if ([[aVisitor classDump] shouldSortMethods])
            methods = [methods sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
        for (CDOCMethod *method in methods)
            [aVisitor visitInstanceMethod:method propertyState:propertyState];

        [aVisitor didVisitOptionalMethods];
    }
}

- (void)visitProperties:(CDVisitor *)aVisitor;
{
    NSArray *array;

    array = properties;
    if ([[aVisitor classDump] shouldSortMethods])
        array = [array sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
    for (CDOCProperty *property in array)
        [aVisitor visitProperty:property];
}

@end
