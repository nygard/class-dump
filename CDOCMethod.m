// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import "CDOCMethod.h"

#import <Foundation/Foundation.h>
#import "CDClassDump.h"
#import "CDTypeFormatter.h"

@implementation CDOCMethod

- (id)init;
{
    [NSException raise:@"RejectUnusedImplementation" format:@"-initWithName:type:imp: is the designated initializer"];
    return nil;
}

- (id)initWithName:(NSString *)aName type:(NSString *)aType imp:(uint32_t)anImp;
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

    return self;
}

- (void)dealloc;
{
    [name release];
    [type release];

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

- (uint32_t)imp;
{
    return imp;
}

- (void)setImp:(uint32_t)newValue;
{
    imp = newValue;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] name: %@, type: %@, imp: 0x%08x",
                     NSStringFromClass([self class]), name, type, imp];
}

- (void)appendToString:(NSMutableString *)resultString classDump:(CDClassDump *)aClassDump symbolReferences:(CDSymbolReferences *)symbolReferences;
{
    NSString *formattedString;

    formattedString = [[aClassDump methodTypeFormatter] formatMethodName:name type:type symbolReferences:symbolReferences];
    if (formattedString != nil) {
        [resultString appendString:formattedString];
        [resultString appendString:@";"];
        if ([aClassDump shouldShowMethodAddresses] == YES && imp != 0)
            [resultString appendFormat:@"\t// IMP=0x%08x", imp];
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
