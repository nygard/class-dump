// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDOCMethod.h"

#import "CDClassDump.h"
#import "CDTypeFormatter.h"
#import "CDTypeParser.h"
#import "NSError-CDExtensions.h"
#import "CDTypeController.h"

@implementation CDOCMethod

- (id)init;
{
    [NSException raise:@"RejectUnusedImplementation" format:@"-initWithName:type:imp: is the designated initializer"];
    return nil;
}

- (id)initWithName:(NSString *)aName type:(NSString *)aType imp:(NSUInteger)anImp;
{
    if ([self initWithName:aName type:aType] == nil)
        return nil;

    [self setImp:anImp];

    return self;
}

- (id)initWithName:(NSString *)aName type:(NSString *)aType;
{
    if ([super init] == nil)
        return nil;

    name = [aName retain];
    type = [aType retain];
    imp = 0;

    hasParsedType = NO;
    parsedMethodTypes = nil;

    return self;
}

- (void)dealloc;
{
    [name release];
    [type release];

    [parsedMethodTypes release];

    [super dealloc];
}

- (NSString *)name;
{
    return name;
}

- (NSString *)type;
{
    return type;
}

- (NSUInteger)imp;
{
    return imp;
}

- (void)setImp:(NSUInteger)newValue;
{
    imp = newValue;
}

- (NSArray *)parsedMethodTypes;
{
    if (hasParsedType == NO) {
        CDTypeParser *parser;
        NSError *error;

        parser = [[CDTypeParser alloc] initWithType:type];
        parsedMethodTypes = [[parser parseMethodType:&error] retain];
        if (parsedMethodTypes == nil)
            NSLog(@"Warning: Parsing method types failed, %@", name);
        [parser release];
        hasParsedType = YES;
    }

    return parsedMethodTypes;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] name: %@, type: %@, imp: 0x%016lx",
                     NSStringFromClass([self class]), name, type, imp];
}

- (void)appendToString:(NSMutableString *)resultString typeController:(CDTypeController *)typeController symbolReferences:(CDSymbolReferences *)symbolReferences;
{
    NSString *formattedString;

    formattedString = [[typeController methodTypeFormatter] formatMethodName:name type:type symbolReferences:symbolReferences];
    if (formattedString != nil) {
        [resultString appendString:formattedString];
        [resultString appendString:@";"];
        if ([typeController shouldShowMethodAddresses] && imp != 0) {
            if ([typeController targetArchUses64BitABI])
                [resultString appendFormat:@"\t// IMP=0x%016lx", imp];
            else
                [resultString appendFormat:@"\t// IMP=0x%08lx", imp];
        }
    } else
        [resultString appendFormat:@"    // Error parsing type: %@, name: %@", type, name];
}

- (NSComparisonResult)ascendingCompareByName:(CDOCMethod *)otherMethod;
{
    return [name compare:[otherMethod name]];
}

- (id)copyWithZone:(NSZone *)zone;
{
    return [[CDOCMethod alloc] initWithName:name type:type imp:imp];
}

@end
