// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDOCMethod.h"

#import "CDClassDump.h"
#import "CDTypeFormatter.h"
#import "CDTypeParser.h"
#import "CDTypeController.h"

@implementation CDOCMethod
{
    NSString *_name;
    NSString *_typeString;
    NSUInteger _address;
    
    BOOL _hasParsedType;
    NSArray *_parsedMethodTypes;
}

- (id)init;
{
    [NSException raise:@"RejectUnusedImplementation" format:@"-initWithName:typeString:imp: is the designated initializer"];
    return nil;
}

- (id)initWithName:(NSString *)name typeString:(NSString *)typeString;
{
    return [self initWithName:name typeString:typeString address:0];
}

- (id)initWithName:(NSString *)name typeString:(NSString *)typeString address:(NSUInteger)address;
{
    if ((self = [super init])) {
        _name = name;
        _typeString = typeString;
        _address = address;
        
        _hasParsedType = NO;
        _parsedMethodTypes = nil;
    }

    return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone;
{
    return [[CDOCMethod alloc] initWithName:self.name typeString:self.typeString address:self.address];
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] name: %@, typeString: %@, address: 0x%016lx",
            NSStringFromClass([self class]), self.name, self.typeString, self.address];
}

#pragma mark -

- (NSArray *)parsedMethodTypes;
{
    if (_hasParsedType == NO) {
        NSError *error = nil;

        CDTypeParser *parser = [[CDTypeParser alloc] initWithString:self.typeString];
        _parsedMethodTypes = [parser parseMethodType:&error];
        if (_parsedMethodTypes == nil)
            NSLog(@"Warning: Parsing method types failed, %@", self.name);
        _hasParsedType = YES;
    }

    return _parsedMethodTypes;
}

- (void)appendToString:(NSMutableString *)resultString typeController:(CDTypeController *)typeController;
{
    NSString *formattedString = [typeController.methodTypeFormatter formatMethodName:self.name typeString:self.typeString];
    if (formattedString != nil) {
        [resultString appendString:formattedString];
        [resultString appendString:@";"];
        if (typeController.shouldShowMethodAddresses && self.address != 0) {
            if (typeController.targetArchUses64BitABI)
                [resultString appendFormat:@"\t// IMP=0x%016lx", self.address];
            else
                [resultString appendFormat:@"\t// IMP=0x%08lx", self.address];
        }
    } else
        [resultString appendFormat:@"    // Error parsing type: %@, name: %@", self.typeString, self.name];
}

#pragma mark - Sorting

- (NSComparisonResult)ascendingCompareByName:(CDOCMethod *)other;
{
    return [self.name compare:other.name];
}

@end
