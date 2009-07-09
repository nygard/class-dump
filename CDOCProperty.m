// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import "CDOCProperty.h"

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

    hasParsedAttributes = NO;
    type = nil;
    attributes = [[NSMutableArray alloc] init];
    attributeStringAfterType = nil;

    return self;
}

- (void)dealloc;
{
    [name release];
    [attributeString release];
    [type release];
    [attributes release];
    [attributeStringAfterType release];

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
    [self parseAttributes];
    return type;
}

- (NSArray *)attributes;
{
    [self parseAttributes];
    return attributes;
}

- (void)_setAttributeStringAfterType:(NSString *)newValue;
{
    if (newValue == attributeStringAfterType)
        return;

    [attributeStringAfterType release];
    attributeStringAfterType = [newValue retain];
}

- (NSString *)attributeStringAfterType;
{
    [self parseAttributes];
    return attributeStringAfterType;
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
- (void)parseAttributes;
{
    NSScanner *scanner;

    if (hasParsedAttributes) {
        return;
    }

    // On 10.nevermind, Finder's TTaskErrorViewController class has a property with a nasty C++ type.  I just knew someone would make this difficult.
    scanner = [[NSScanner alloc] initWithString:attributeString];

    if ([scanner scanString:@"T" intoString:NULL]) {
        NSError *error;
        NSRange typeRange;
        CDTypeParser *parser;

        typeRange.location = [scanner scanLocation];
        parser = [[CDTypeParser alloc] initWithType:[[scanner string] substringFromIndex:[scanner scanLocation]]];
        type = [[parser parseType:&error] retain];
        if (type != nil) {
            typeRange.length = [[[parser lexer] scanner] scanLocation];

            [self _setAttributeStringAfterType:[attributeString substringFromIndex:NSMaxRange(typeRange)]];
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

    hasParsedAttributes = YES;
    // And then if parsedType is nil, we know we couldn't parse the type.
}

@end
