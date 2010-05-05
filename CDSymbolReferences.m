// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDSymbolReferences.h"

@implementation CDSymbolReferences

- (id)init;
{
    if ([super init] == nil)
        return nil;

    frameworkNamesByClassName = nil;
    frameworkNamesByProtocolName = nil;

    classes = [[NSMutableSet alloc] init];
    protocols = [[NSMutableSet alloc] init];

    return self;
}

- (void)dealloc;
{
    [frameworkNamesByClassName release];
    [frameworkNamesByProtocolName release];

    [classes release];
    [protocols release];

    [super dealloc];
}

- (void)setFrameworkNamesByClassName:(NSDictionary *)newValue;
{
    if (newValue == frameworkNamesByClassName)
        return;

    [frameworkNamesByClassName release];
    frameworkNamesByClassName = [newValue retain];
}

- (void)setFrameworkNamesByProtocolName:(NSDictionary *)newValue;
{
    if (newValue == frameworkNamesByProtocolName)
        return;

    [frameworkNamesByProtocolName release];
    frameworkNamesByProtocolName = [newValue retain];
}

- (NSString *)frameworkForClassName:(NSString *)aClassName;
{
    return [frameworkNamesByClassName objectForKey:aClassName];
}

- (NSString *)frameworkForProtocolName:(NSString *)aProtocolName;
{
    return [frameworkNamesByProtocolName objectForKey:aProtocolName];
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
    return [NSString stringWithFormat:@"<%@:%p> frameworkNamesByClassName: %@, frameworkNamesByProtocolName: %@, classes: %@, protocols: %@",
                     NSStringFromClass([self class]), self,
                     frameworkNamesByClassName, frameworkNamesByProtocolName,
                     [self classes], [self protocols]];
}

- (void)_appendToString:(NSMutableString *)resultString;
{
    NSArray *names;

    names = [self protocols];
    for (NSString *name in names) {
        NSString *str;

        str = [self importStringForProtocolName:name];
        if (str != nil)
            [resultString appendString:str];
    }
    if ([names count] > 0)
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

- (void)removeAllReferences;
{
    [classes removeAllObjects];
    [protocols removeAllObjects];
}

- (NSString *)importStringForClassName:(NSString *)aClassName;
{
    if (aClassName != nil) {
        NSString *framework;

        framework = [self frameworkForClassName:aClassName];
        if (framework == nil)
            return [NSString stringWithFormat:@"#import \"%@.h\"\n", aClassName];
        else
            return [NSString stringWithFormat:@"#import <%@/%@.h>\n", framework, aClassName];
    }

    return nil;
}

- (NSString *)importStringForProtocolName:(NSString *)aProtocolName;
{
    if (aProtocolName != nil) {
        NSString *framework;

        framework = [self frameworkForClassName:aProtocolName];
        if (framework == nil)
            return [NSString stringWithFormat:@"#import \"%@-Protocol.h\"\n", aProtocolName];
        else
            return [NSString stringWithFormat:@"#import <%@/%@-Protocol.h>\n", framework, aProtocolName];
    }

    return nil;
}

@end
