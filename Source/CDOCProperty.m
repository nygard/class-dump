// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDOCProperty.h"

#import "NSString-Extensions.h"
#import "CDTypeParser.h"
#import "CDTypeLexer.h"

// http://developer.apple.com/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html

static BOOL debug = NO;

@implementation CDOCProperty
{
    NSString *name;
    NSString *attributeString;
    
    CDType *type;
    NSMutableArray *attributes;
    
    BOOL hasParsedAttributes;
    NSString *attributeStringAfterType;
    NSString *customGetter;
    NSString *customSetter;
    
    BOOL isReadOnly;
    BOOL isDynamic;
}

- (id)initWithName:(NSString *)aName attributes:(NSString *)someAttributes;
{
    if ((self = [super init])) {
        name = [aName retain];
        attributeString = [someAttributes retain];
        type = nil;
        attributes = [[NSMutableArray alloc] init];
        
        hasParsedAttributes = NO;
        attributeStringAfterType = nil;
        customGetter = nil;
        customSetter = nil;
        
        isReadOnly = NO;
        isDynamic = NO;
        
        [self _parseAttributes];
    }

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

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> name: %@, attributeString: %@",
            NSStringFromClass([self class]), self,
            name, attributeString];
}

#pragma mark -

@synthesize name;
@synthesize attributeString;
@synthesize type;
@synthesize attributes;
@synthesize attributeStringAfterType;

- (NSString *)defaultGetter;
{
    return self.name;
}

- (NSString *)defaultSetter;
{
    return [NSString stringWithFormat:@"set%@:", [self.name capitalizeFirstCharacter]];
}

@synthesize customGetter;
@synthesize customSetter;

- (NSString *)getter;
{
    if (self.customGetter != nil)
        return self.customGetter;

    return self.defaultGetter;
}

- (NSString *)setter;
{
    if (self.customSetter != nil)
        return self.customSetter;

    return self.defaultSetter;
}

@synthesize isReadOnly;
@synthesize isDynamic;

#pragma mark - Sorting

- (NSComparisonResult)ascendingCompareByName:(CDOCProperty *)otherProperty;
{
    return [self.name compare:otherProperty.name];
}

#pragma mark -

// TODO (2009-07-09): Really, I don't need to require the "T" at the start.
- (void)_parseAttributes;
{
    // On 10.6, Finder's TTaskErrorViewController class has a property with a nasty C++ type.  I just knew someone would make this difficult.
    NSScanner *scanner = [[NSScanner alloc] initWithString:self.attributeString];

    if ([scanner scanString:@"T" intoString:NULL]) {
        NSError *error = nil;
        NSRange typeRange;

        typeRange.location = [scanner scanLocation];
        CDTypeParser *parser = [[CDTypeParser alloc] initWithType:[[scanner string] substringFromIndex:[scanner scanLocation]]];
        type = [[parser parseType:&error] retain];
        if (type != nil) {
            typeRange.length = [[[parser lexer] scanner] scanLocation];

            NSString *str = [attributeString substringFromIndex:NSMaxRange(typeRange)];

            // Filter out so we don't get an empty string as an attribute.
            if ([str hasPrefix:@","])
                str = [str substringFromIndex:1];

            self.attributeStringAfterType = str;
            if ([self.attributeStringAfterType length] > 0) {
                [attributes addObjectsFromArray:[self.attributeStringAfterType componentsSeparatedByString:@","]];
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
            isReadOnly = YES;
        else if ([attr hasPrefix:@"D"])
            isDynamic = YES;
        else if ([attr hasPrefix:@"G"])
            self.customGetter = [attr substringFromIndex:1];
        else if ([attr hasPrefix:@"S"])
            self.customSetter = [attr substringFromIndex:1];
    }

    hasParsedAttributes = YES;
    // And then if parsedType is nil, we know we couldn't parse the type.
}

@end
