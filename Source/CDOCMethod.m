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
    NSString *_type;
    NSUInteger _imp;
    
    BOOL _hasParsedType;
    NSArray *_parsedMethodTypes;
}

- (id)init;
{
    [NSException raise:@"RejectUnusedImplementation" format:@"-initWithName:type:imp: is the designated initializer"];
    return nil;
}

- (id)initWithName:(NSString *)name type:(NSString *)type imp:(NSUInteger)imp;
{
    if ((self = [self initWithName:name type:type])) {
        [self setImp:imp];
    }

    return self;
}

- (id)initWithName:(NSString *)name type:(NSString *)type;
{
    if ((self = [super init])) {
        _name = name;
        _type = type;
        _imp = 0;
        
        _hasParsedType = NO;
        _parsedMethodTypes = nil;
    }

    return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone;
{
    return [[CDOCMethod alloc] initWithName:self.name type:self.type imp:self.imp];
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] name: %@, type: %@, imp: 0x%016lx",
            NSStringFromClass([self class]), self.name, self.type, self.imp];
}

#pragma mark -

- (NSArray *)parsedMethodTypes;
{
    if (_hasParsedType == NO) {
        NSError *error = nil;

        CDTypeParser *parser = [[CDTypeParser alloc] initWithType:self.type];
        _parsedMethodTypes = [parser parseMethodType:&error];
        if (_parsedMethodTypes == nil)
            NSLog(@"Warning: Parsing method types failed, %@", self.name);
        _hasParsedType = YES;
    }

    return _parsedMethodTypes;
}

- (void)appendToString:(NSMutableString *)resultString typeController:(CDTypeController *)typeController;
{
    NSString *formattedString = [typeController.methodTypeFormatter formatMethodName:self.name type:self.type];
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
        [resultString appendFormat:@"    // Error parsing type: %@, name: %@", self.type, self.name];
}

#pragma mark - Sorting

- (NSComparisonResult)ascendingCompareByName:(CDOCMethod *)otherMethod;
{
    return [self.name compare:otherMethod.name];
}

@end
