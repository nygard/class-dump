#import "CDOCProtocol.h"

#import <Foundation/Foundation.h>
#import "NSArray-Extensions.h"
#import "CDOCSymtab.h"
#import "CDTypeParser.h"

@implementation CDOCProtocol

- (id)init;
{
    if ([super init] == nil)
        return nil;

    nonretainedSymtab = nil;
    name = nil;
    protocols = [[NSMutableArray alloc] init];
    classMethods = nil;
    instanceMethods = nil;
    adoptedProtocolNames = [[NSMutableSet alloc] init];

    return self;
}

- (void)dealloc;
{
    nonretainedSymtab = nil;
    [name release];
    [protocols release];
    [classMethods release];
    [instanceMethods release];
    [adoptedProtocolNames release];

    [super dealloc];
}

- (CDOCSymtab *)symtab;
{
    return nonretainedSymtab;
}

- (void)setSymtab:(CDOCSymtab *)newSymtab;
{
    nonretainedSymtab = newSymtab;
    [protocols makeObjectsPerformSelector:@selector(setSymtab:) withObject:newSymtab];
}

- (CDClassDump2 *)classDumper;
{
    return [[self symtab] classDumper];
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
        [aProtocol setSymtab:[self symtab]];
        [protocols addObject:aProtocol];
        [adoptedProtocolNames addObject:[aProtocol name]];
    }
}

- (void)removeProtocol:(CDOCProtocol *)aProtocol;
{
    [aProtocol setSymtab:nil];
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

    [classMethods makeObjectsPerformSelector:@selector(setProtocol:) withObject:nil];
    [classMethods release];
    classMethods = [newClassMethods retain];
    [classMethods makeObjectsPerformSelector:@selector(setProtocol:) withObject:self];
}

- (NSArray *)instanceMethods;
{
    return instanceMethods;
}

- (void)setInstanceMethods:(NSArray *)newInstanceMethods;
{
    if (newInstanceMethods == instanceMethods)
        return;

    [instanceMethods makeObjectsPerformSelector:@selector(setProtocol:) withObject:nil];
    [instanceMethods release];
    instanceMethods = [newInstanceMethods retain];
    [instanceMethods makeObjectsPerformSelector:@selector(setProtocol:) withObject:self];
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] name: %@, protocols: %d, class methods: %d, instance methods: %d",
                     NSStringFromClass([self class]), name, [protocols count], [classMethods count], [instanceMethods count]];
}

- (void)appendToString:(NSMutableString *)resultString;
{
    int count, index;
    NSArray *sortedMethods;

    [resultString appendFormat:@"@protocol %@", name];
    if ([protocols count] > 0)
        [resultString appendFormat:@" <%@>", [[protocols arrayByMappingSelector:@selector(name)] componentsJoinedByString:@", "]];

    [resultString appendString:@"\n"];

    sortedMethods = [classMethods sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
    count = [sortedMethods count];
    for (index = 0; index < count; index++) {
        [resultString appendString:@"+ "];
        [[sortedMethods objectAtIndex:index] appendToString:resultString];
        [resultString appendString:@"\n"];
    }

    sortedMethods = [instanceMethods sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
    count = [sortedMethods count];
    for (index = 0; index < count; index++) {
        [resultString appendString:@"- "];
        [[sortedMethods objectAtIndex:index] appendToString:resultString];
        [resultString appendString:@"\n"];
    }
    [resultString appendString:@"@end\n\n"];
}

- (void)registerStructsWithObject:(id <CDStructRegistration>)anObject;
{
    int count, index;
    CDTypeParser *parser;
    NSArray *methodTypes;

    count = [classMethods count];
    for (index = 0; index < count; index++) {
        parser = [[CDTypeParser alloc] initWithType:[[classMethods objectAtIndex:index] type]];
        methodTypes = [parser parseMethodType];
        [[methodTypes arrayByMappingSelector:@selector(type)] makeObjectsPerformSelector:_cmd withObject:anObject];
        [parser release];
    }

    count = [instanceMethods count];
    for (index = 0; index < count; index++) {
        parser = [[CDTypeParser alloc] initWithType:[[instanceMethods objectAtIndex:index] type]];
        methodTypes = [parser parseMethodType];
        [[methodTypes arrayByMappingSelector:@selector(type)] makeObjectsPerformSelector:_cmd withObject:anObject];
        [parser release];
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
