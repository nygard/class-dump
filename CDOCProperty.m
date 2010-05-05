// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import "CDOCProperty.h"

#import "NSString-Extensions.h"
#import "CDTypeParser.h"
#import "CDTypeLexer.h"

// http://developer.apple.com/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html

static BOOL debug = NO;

@implementation CDOCProperty

- (id)initWithName:(NSString *)aName attributes:(NSString *)someAttributes;
{
    if ([super init] == nil)
        return nil;

    name = [aName retain];
    attributeString = [someAttributes retain];
    type = nil;
    attributes = [[NSMutableArray alloc] init];

    hasParsedAttributes = NO;
    attributeStringAfterType = nil;
    customGetter = nil;
    customSetter = nil;

    flags.isReadOnly = NO;
    flags.isDynamic = NO;

    [self _parseAttributes];

    return self;
}

- (void)dealloc;
{
    [name release];
    [attributeString release];
    [type release];
    [attributes release];

    [attributeStringAfterType release];
    [customGetter release];
    [customSetter release];

    [super dealloc];
}

- (NSString *)name;
{
    return name;
}

- (NSString *)attributeString;
{
    return attributeString;
}

- (CDType *)type;
{
    return type;
}

- (NSArray *)attributes;
{
    return attributes;
}

- (NSString *)attributeStringAfterType;
{
    return attributeStringAfterType;
}

- (void)_setAttributeStringAfterType:(NSString *)newValue;
{
    if (newValue == attributeStringAfterType)
        return;

    [attributeStringAfterType release];
    attributeStringAfterType = [newValue retain];
}

- (NSString *)defaultGetter;
{
    return name;
}

- (NSString *)defaultSetter;
{
    return [NSString stringWithFormat:@"set%@:", [name capitalizeFirstCharacter]];
}

- (NSString *)customGetter;
{
    return customGetter;
}

- (void)_setCustomGetter:(NSString *)newStr;
{
    if (newStr == customGetter)
        return;

    [customGetter release];
    customGetter = [newStr retain];
}

- (NSString *)customSetter;
{
    return customSetter;
}

- (void)_setCustomSetter:(NSString *)newStr;
{
    if (newStr == customSetter)
        return;

    [customSetter release];
    customSetter = [newStr retain];
}

- (NSString *)getter;
{
    if (customGetter != nil)
        return customGetter;

    return [self defaultGetter];
}

- (NSString *)setter;
{
    if (customSetter != nil)
        return customSetter;

    return [self defaultSetter];
}

- (BOOL)isReadOnly;
{
    return flags.isReadOnly;
}

- (BOOL)isDynamic;
{
    return flags.isDynamic;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> name: %@, attributeString: %@",
                     NSStringFromClass([self class]), self,
                     name, attributeString];
}

- (NSComparisonResult)ascendingCompareByName:(CDOCProperty *)otherProperty;
{
    return [name compare:[otherProperty name]];
}

// TODO (2009-07-09): Really, I don't need to require the "T" at the start.
- (void)_parseAttributes;
{
    NSScanner *scanner;

    // On 10.6, Finder's TTaskErrorViewController class has a property with a nasty C++ type.  I just knew someone would make this difficult.
    scanner = [[NSScanner alloc] initWithString:attributeString];

    if ([scanner scanString:@"T" intoString:NULL]) {
        NSError *error;
        NSRange typeRange;
        CDTypeParser *parser;

        typeRange.location = [scanner scanLocation];
        parser = [[CDTypeParser alloc] initWithType:[[scanner string] substringFromIndex:[scanner scanLocation]]];
        type = [[parser parseType:&error] retain];
        if (type != nil) {
            NSString *str;

            typeRange.length = [[[parser lexer] scanner] scanLocation];

            str = [attributeString substringFromIndex:NSMaxRange(typeRange)];

            // Filter out so we don't get an empty string as an attribute.
            if ([str hasPrefix:@","])
                str = [str substringFromIndex:1];

            [self _setAttributeStringAfterType:str];
            if ([attributeStringAfterType length] > 0) {
                [attributes addObjectsFromArray:[attributeStringAfterType componentsSeparatedByString:@","]];
            } else {
                // For a simple case like "Ti", we'd get the empty string.
                // Then, using componentsSeparatedByString:, since it has no separator we'd get back an array containing the (empty) string
            }
        }

        [parser release];
    } else {
        if (debug) NSLog(@"Error: Property attributes should begin with the type ('T') attribute, property name: %@", name);
    }

    [scanner release];

    for (NSString *attr in attributes) {
        if ([attr hasPrefix:@"R"])
            flags.isReadOnly = YES;
        else if ([attr hasPrefix:@"D"])
            flags.isDynamic = YES;
        else if ([attr hasPrefix:@"G"])
            [self _setCustomGetter:[attr substringFromIndex:1]];
        else if ([attr hasPrefix:@"S"])
            [self _setCustomSetter:[attr substringFromIndex:1]];
    }

    hasParsedAttributes = YES;
    // And then if parsedType is nil, we know we couldn't parse the type.
}

@end
