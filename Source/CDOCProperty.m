// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDOCProperty.h"

#import "CDTypeParser.h"
#import "CDTypeLexer.h"
#import "CDType.h"

// http://developer.apple.com/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html

static BOOL debug = NO;

@interface CDOCProperty ()
@end

#pragma mark -

@implementation CDOCProperty
{
    NSString *_name;
    NSString *_attributeString;
    
    CDType *_type;
    NSMutableArray *_attributes;
    
    BOOL _hasParsedAttributes;
    NSString *_attributeStringAfterType;
    NSString *_customGetter;
    NSString *_customSetter;
    
    BOOL _isReadOnly;
    BOOL _isDynamic;
}

- (id)initWithName:(NSString *)name attributes:(NSString *)attributes;
{
    if ((self = [super init])) {
        _name = name;
        _attributeString = attributes;
        _type = nil;
        _attributes = [[NSMutableArray alloc] init];
        
        _hasParsedAttributes = NO;
        _attributeStringAfterType = nil;
        _customGetter = nil;
        _customSetter = nil;
        
        _isReadOnly = NO;
        _isDynamic = NO;
        
        [self _parseAttributes];
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> name: %@, attributeString: %@",
            NSStringFromClass([self class]), self,
            self.name, self.attributeString];
}

#pragma mark -

- (NSString *)defaultGetter;
{
    return self.name;
}

- (NSString *)defaultSetter;
{
    return [NSString stringWithFormat:@"set%@:", [self.name capitalizeFirstCharacter]];
}

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

#pragma mark - Sorting

- (NSComparisonResult)ascendingCompareByName:(CDOCProperty *)other;
{
    return [self.name compare:other.name];
}

#pragma mark -

// TODO: (2009-07-09) Really, I don't need to require the "T" at the start.
- (void)_parseAttributes;
{
    // On 10.6, Finder's TTaskErrorViewController class has a property with a nasty C++ type.  I just knew someone would make this difficult.
    NSScanner *scanner = [[NSScanner alloc] initWithString:self.attributeString];

    if ([scanner scanString:@"T" intoString:NULL]) {
        NSError *error = nil;
        NSRange typeRange;

        typeRange.location = [scanner scanLocation];
        CDTypeParser *parser = [[CDTypeParser alloc] initWithString:[[scanner string] substringFromIndex:[scanner scanLocation]]];
        _type = [parser parseType:&error];
        if (_type != nil) {
            typeRange.length = [parser.lexer.scanner scanLocation];

            NSString *str = [self.attributeString substringFromIndex:NSMaxRange(typeRange)];

            // Filter out so we don't get an empty string as an attribute.
            if ([str hasPrefix:@","])
                str = [str substringFromIndex:1];

            self.attributeStringAfterType = str;
            if ([self.attributeStringAfterType length] > 0) {
                [_attributes addObjectsFromArray:[self.attributeStringAfterType componentsSeparatedByString:@","]];
            } else {
                // For a simple case like "Ti", we'd get the empty string.
                // Then, using componentsSeparatedByString:, since it has no separator we'd get back an array containing the (empty) string
            }
        }
    } else {
        if (debug) NSLog(@"Error: Property attributes should begin with the type ('T') attribute, property name: %@", self.name);
    }

    for (NSString *attr in _attributes) {
        if ([attr hasPrefix:@"R"])
            _isReadOnly = YES;
        else if ([attr hasPrefix:@"D"])
            _isDynamic = YES;
        else if ([attr hasPrefix:@"G"])
            self.customGetter = [attr substringFromIndex:1];
        else if ([attr hasPrefix:@"S"])
            self.customSetter = [attr substringFromIndex:1];
    }

    _hasParsedAttributes = YES;
    // And then if parsedType is nil, we know we couldn't parse the type.
}

@end
