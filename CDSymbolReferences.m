//  This file is part of APPNAME, SHORT DESCRIPTION
//  Copyright (C) 2004 Steve Nygard.  All rights reserved.

#import "CDSymbolReferences.h"

#import "rcsid.h"
#import <Foundation/Foundation.h>

RCS_ID("$Header: /Volumes/Data/tmp/Tools/class-dump/CDSymbolReferences.m,v 1.1 2004/02/02 21:46:22 nygard Exp $");

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
        [resultString appendFormat:@"@class %@;\n", [names componentsJoinedByString:@", "]];
    }
    if (count > 0)
        [resultString appendString:@"\n"];
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
