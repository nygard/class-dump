// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDSymbolReferences.h"

@interface CDSymbolReferences ()

@property (readonly) NSMutableSet *classes;
@property (readonly) NSMutableSet *protocols;

@property (nonatomic, readonly) NSArray *classesSortedByName;
@property (nonatomic, readonly) NSArray *protocolsSortedByName;

- (void)_appendToString:(NSMutableString *)resultString;

@end

#pragma mark -

@implementation CDSymbolReferences
{
    NSDictionary *frameworkNamesByClassName;
    NSDictionary *frameworkNamesByProtocolName;
    
    NSMutableSet *classes;
    NSMutableSet *protocols;
}

- (id)init;
{
    if ((self = [super init])) {
        frameworkNamesByClassName = nil;
        frameworkNamesByProtocolName = nil;
        
        classes = [[NSMutableSet alloc] init];
        protocols = [[NSMutableSet alloc] init];
    }

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

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> frameworkNamesByClassName: %@, frameworkNamesByProtocolName: %@, classes: %@, protocols: %@",
            NSStringFromClass([self class]), self,
            self.frameworkNamesByClassName, self.frameworkNamesByProtocolName,
            self.classesSortedByName, self.protocolsSortedByName];
}

#pragma mark -

@synthesize frameworkNamesByClassName;
@synthesize frameworkNamesByProtocolName;

- (NSString *)frameworkForClassName:(NSString *)className;
{
    return [frameworkNamesByClassName objectForKey:className];
}

- (NSString *)frameworkForProtocolName:(NSString *)protocolName;
{
    return [frameworkNamesByProtocolName objectForKey:protocolName];
}

- (void)addClassName:(NSString *)className;
{
    [classes addObject:className];
}

- (void)removeClassName:(NSString *)className;
{
    if (className != nil)
        [classes removeObject:className];
}

- (void)addProtocolName:(NSString *)protocolName;
{
    [protocols addObject:protocolName];
}

- (void)addProtocolNamesFromArray:(NSArray *)protocolNames;
{
    [protocols addObjectsFromArray:protocolNames];
}

- (NSString *)referenceString;
{
    NSMutableString *referenceString = [[[NSMutableString alloc] init] autorelease];
    [self _appendToString:referenceString];

    if ([referenceString length] == 0)
        return nil;

    return [[referenceString copy] autorelease];
}

- (void)removeAllReferences;
{
    [classes removeAllObjects];
    [protocols removeAllObjects];
}

- (NSString *)importStringForClassName:(NSString *)className;
{
    if (className != nil) {
        NSString *framework = [self frameworkForClassName:className];
        if (framework == nil)
            return [NSString stringWithFormat:@"#import \"%@.h\"\n", className];
        else
            return [NSString stringWithFormat:@"#import <%@/%@.h>\n", framework, className];
    }

    return nil;
}

- (NSString *)importStringForProtocolName:(NSString *)protocolName;
{
    if (protocolName != nil) {
        NSString *framework = [self frameworkForClassName:protocolName];
        if (framework == nil)
            return [NSString stringWithFormat:@"#import \"%@-Protocol.h\"\n", protocolName];
        else
            return [NSString stringWithFormat:@"#import <%@/%@-Protocol.h>\n", framework, protocolName];
    }

    return nil;
}

#pragma mark -

@synthesize classes;
@synthesize protocols;

- (NSArray *)classesSortedByName;
{
    return [[self.classes allObjects] sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray *)protocolsSortedByName;
{
    return [[self.protocols allObjects] sortedArrayUsingSelector:@selector(compare:)];
}

- (void)_appendToString:(NSMutableString *)resultString;
{
    NSArray *names = self.protocolsSortedByName;
    for (NSString *name in names) {
        NSString *str = [self importStringForProtocolName:name];
        if (str != nil)
            [resultString appendString:str];
    }
    if ([names count] > 0)
        [resultString appendString:@"\n"];
    
    names = self.classesSortedByName;
    if ([names count] > 0) {
        [resultString appendFormat:@"@class %@;\n\n", [names componentsJoinedByString:@", "]];
    }
}

@end
