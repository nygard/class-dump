// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDOCMethod.h"

#import "CDClassDump.h"
#import "CDTypeFormatter.h"
#import "CDTypeParser.h"
#import "CDTypeController.h"

@implementation CDOCMethod
{
    NSString *_name;
    NSString *_typeString;
    NSUInteger _imp;
    
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
    return [self initWithName:name typeString:typeString imp:0];
}

- (id)initWithName:(NSString *)name typeString:(NSString *)typeString imp:(NSUInteger)imp;
{
    if ((self = [super init])) {
        _name = name;
        _typeString = typeString;
        _imp = imp;
        
        _hasParsedType = NO;
        _parsedMethodTypes = nil;
    }

    return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone;
{
    return [[CDOCMethod alloc] initWithName:self.name typeString:self.typeString imp:self.imp];
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] name: %@, typeString: %@, imp: 0x%016lx",
            NSStringFromClass([self class]), self.name, self.typeString, self.imp];
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
        if (typeController.shouldShowMethodAddresses && self.imp != 0) {
            if (typeController.targetArchUses64BitABI)
                [resultString appendFormat:@"\t// IMP=0x%016lx", self.imp];
            else
                [resultString appendFormat:@"\t// IMP=0x%08lx", self.imp];
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
