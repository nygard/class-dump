//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import "CDSymbolReferences.h"

#import "rcsid.h"
#import <Foundation/Foundation.h>

RCS_ID("$Header: /Volumes/Data/tmp/Tools/class-dump/CDSymbolReferences.m,v 1.3 2004/02/03 22:18:37 nygard Exp $");

@implementation CDSymbolReferences

- (id)init;
{
    if ([super init] == nil)
        return nil;

    classes = [[NSMutableSet alloc] init];
    protocols = [[NSMutableSet alloc] init];

    return self;
}

- (void)dealloc;
{
    [classes release];
    [protocols release];

    [super dealloc];
}

- (NSArray *)classes;
{
    return [[classes allObjects] sortedArrayUsingSelector:@selector(compare:)];
}

- (void)addClassName:(NSString *)aClassName;
{
    [classes addObject:aClassName];
}

- (void)removeClassName:(NSString *)aClassName;
{
    if (aClassName != nil)
        [classes removeObject:aClassName];
}

- (NSArray *)protocols;
{
    return [[protocols allObjects] sortedArrayUsingSelector:@selector(compare:)];
}

- (void)addProtocolName:(NSString *)aProtocolName;
{
    [protocols addObject:aProtocolName];
}

- (void)addProtocolNamesFromArray:(NSArray *)protocolNames;
{
    [protocols addObjectsFromArray:protocolNames];
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> classes: %@, protocols: %@", NSStringFromClass([self class]), self, [self classes], [self protocols]];
}

- (void)_appendToString:(NSMutableString *)resultString;
{
    NSArray *names;
    int count, index;

    names = [self protocols];
    count = [names count];
    for (index = 0; index < count; index++) {
        [resultString appendFormat:@"#import \"%@Protocol.h\"\n", [names objectAtIndex:index]];
    }
    if (count > 0)
        [resultString appendString:@"\n"];

    names = [self classes];
    if ([names count] > 0) {
        [resultString appendFormat:@"@class %@;\n\n", [names componentsJoinedByString:@", "]];
    }
}

- (NSString *)referenceString;
{
    NSMutableString *referenceString;

    referenceString = [[[NSMutableString alloc] init] autorelease];
    [self _appendToString:referenceString];

    if ([referenceString length] == 0)
        return nil;

    return referenceString;
}

@end
