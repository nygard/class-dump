//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import "CDOCProtocol.h"

#import "rcsid.h"
#import <Foundation/Foundation.h>
#import "NSArray-Extensions.h"
#import "CDClassDump.h"
#import "CDOCMethod.h"
#import "CDOCSymtab.h"
#import "CDSymbolReferences.h"
#import "CDTypeParser.h"

RCS_ID("$Header: /Volumes/Data/tmp/Tools/class-dump/CDOCProtocol.m,v 1.23 2004/02/03 04:00:21 nygard Exp $");

@implementation CDOCProtocol

- (id)init;
{
    if ([super init] == nil)
        return nil;

    name = nil;
    protocols = [[NSMutableArray alloc] init];
    classMethods = nil;
    instanceMethods = nil;
    adoptedProtocolNames = [[NSMutableSet alloc] init];

    return self;
}

- (void)dealloc;
{
    [name release];
    [protocols release];
    [classMethods release];
    [instanceMethods release];
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

- (void)addProtocolsFromArray:(NSArray *)newProtocols;
{
    int count, index;

    count = [newProtocols count];
    for (index = 0; index < count; index++)
        [self addProtocol:[newProtocols objectAtIndex:index]];
}

- (NSArray *)classMethods;
{
    return classMethods;
}

- (void)setClassMethods:(NSArray *)newClassMethods;
{
    if (newClassMethods == classMethods)
        return;

    [classMethods release];
    classMethods = [newClassMethods retain];
}

- (NSArray *)instanceMethods;
{
    return instanceMethods;
}

- (void)setInstanceMethods:(NSArray *)newInstanceMethods;
{
    if (newInstanceMethods == instanceMethods)
        return;

    [instanceMethods release];
    instanceMethods = [newInstanceMethods retain];
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] name: %@, protocols: %d, class methods: %d, instance methods: %d",
                     NSStringFromClass([self class]), name, [protocols count], [classMethods count], [instanceMethods count]];
}

- (void)appendToString:(NSMutableString *)resultString classDump:(CDClassDump2 *)aClassDump symbolReferences:(CDSymbolReferences *)symbolReferences;
{
    if ([aClassDump shouldMatchRegex] == YES && [aClassDump regexMatchesString:[self name]] == NO)
        return;

    [resultString appendFormat:@"@protocol %@", name];
    if ([protocols count] > 0) {
        [resultString appendFormat:@" <%@>", [[protocols arrayByMappingSelector:@selector(name)] componentsJoinedByString:@", "]];
        [symbolReferences addProtocolNamesFromArray:[protocols arrayByMappingSelector:@selector(name)]];
    }

    [resultString appendString:@"\n"];
    [self appendMethodsToString:resultString classDump:aClassDump symbolReferences:symbolReferences];
    [resultString appendString:@"@end\n\n"];
}

- (void)appendMethodsToString:(NSMutableString *)resultString classDump:(CDClassDump2 *)aClassDump symbolReferences:(CDSymbolReferences *)symbolReferences;
{
    int count, index;
    NSArray *methods;

    if ([aClassDump shouldSortMethods] == YES)
        methods = [classMethods sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
    else
        methods = classMethods;

    count = [methods count];
    if (count > 0) {
        for (index = 0; index < count; index++) {
            [resultString appendString:@"+ "];
            [[methods objectAtIndex:index] appendToString:resultString classDump:aClassDump symbolReferences:symbolReferences];
            [resultString appendString:@"\n"];
        }
    }

    if ([aClassDump shouldSortMethods] == YES)
        methods = [instanceMethods sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
    else
        methods = instanceMethods;

    count = [methods count];
    if (count > 0) {
        for (index = 0; index < count; index++) {
            [resultString appendString:@"- "];
            [[methods objectAtIndex:index] appendToString:resultString classDump:aClassDump symbolReferences:symbolReferences];
            [resultString appendString:@"\n"];
        }
    }
}

- (void)registerStructuresWithObject:(id <CDStructureRegistration>)anObject phase:(int)phase;
{
    [self registerStructuresFromMethods:classMethods withObject:anObject phase:phase];
    [self registerStructuresFromMethods:instanceMethods withObject:anObject phase:phase];
}

- (void)registerStructuresFromMethods:(NSArray *)methods withObject:(id <CDStructureRegistration>)anObject phase:(int)phase;
{
    int count, index;
    CDTypeParser *parser;
    NSArray *methodTypes;

    count = [methods count];
    for (index = 0; index < count; index++) {
        parser = [[CDTypeParser alloc] initWithType:[(CDOCMethod *)[methods objectAtIndex:index] type]];
        methodTypes = [parser parseMethodType];
        if (methodTypes == nil)
            NSLog(@"Warning: Parsing method types failed, %@", [(CDOCMethod *)[methods objectAtIndex:index] name]);
        [self registerStructuresFromMethodTypes:methodTypes withObject:anObject phase:phase];
        [parser release];
    }
}

- (void)registerStructuresFromMethodTypes:(NSArray *)methodTypes withObject:(id <CDStructureRegistration>)anObject phase:(int)phase;
{
    int count, index;

    count = [methodTypes count];
    for (index = 0; index < count; index++) {
        [[methodTypes objectAtIndex:index] registerStructuresWithObject:anObject phase:phase];
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

@end
