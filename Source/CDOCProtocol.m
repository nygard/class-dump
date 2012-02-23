// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

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

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> name: %@, protocols: %d, class methods: %d, instance methods: %d",
            NSStringFromClass([self class]), self, name, [protocols count], [classMethods count], [instanceMethods count]];
}

#pragma mark -

@synthesize name;
@synthesize protocols;

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

#pragma mark - Sorting

- (NSString *)sortableName;
{
    return name;
}

- (NSComparisonResult)ascendingCompareByName:(CDOCProtocol *)otherProtocol;
{
    return [[self sortableName] compare:[otherProtocol sortableName]];
}

#pragma mark -

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
    if ([[aVisitor classDump] shouldMatchRegex] && [[aVisitor classDump] regexMatchesString:[self name]] == NO)
        return;

    // Wonderful.  Need to typecast because there's also -[NSHTTPCookie initWithProperties:] that takes a dictionary.
    CDVisitorPropertyState *propertyState = [(CDVisitorPropertyState *)[CDVisitorPropertyState alloc] initWithProperties:[self properties]];

    [aVisitor willVisitProtocol:self];

    //[aVisitor willVisitPropertiesOfProtocol:self];
    //[self visitProperties:aVisitor];
    //[aVisitor didVisitPropertiesOfProtocol:self];

    [self visitMethods:aVisitor propertyState:propertyState];

    // @optional properties will generate optional instance methods, and we'll emit @property in the @optional section.
    [aVisitor visitRemainingProperties:propertyState];

    [aVisitor didVisitProtocol:self];

    [propertyState release];
}

- (void)visitMethods:(CDVisitor *)aVisitor propertyState:(CDVisitorPropertyState *)propertyState;
{
    NSArray *methods = classMethods;
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
    NSArray *array = properties;
    if ([[aVisitor classDump] shouldSortMethods])
        array = [array sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
    for (CDOCProperty *property in array)
        [aVisitor visitProperty:property];
}

@end
