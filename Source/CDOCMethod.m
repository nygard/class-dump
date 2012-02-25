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
    NSString *name;
    NSString *type;
    NSUInteger imp;
    
    BOOL hasParsedType;
    NSArray *parsedMethodTypes;
}

- (id)init;
{
    [NSException raise:@"RejectUnusedImplementation" format:@"-initWithName:type:imp: is the designated initializer"];
    return nil;
}

- (id)initWithName:(NSString *)aName type:(NSString *)aType imp:(NSUInteger)anImp;
{
    if ((self = [self initWithName:aName type:aType])) {
        [self setImp:anImp];
    }

    return self;
}

- (id)initWithName:(NSString *)aName type:(NSString *)aType;
{
    if ((self = [super init])) {
        name = aName;
        type = aType;
        imp = 0;
        
        hasParsedType = NO;
        parsedMethodTypes = nil;
    }

    return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone;
{
    return [[CDOCMethod alloc] initWithName:name type:type imp:imp];
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] name: %@, type: %@, imp: 0x%016lx",
            NSStringFromClass([self class]), name, type, imp];
}

#pragma mark -

@synthesize name;
@synthesize type;
@synthesize imp;

- (NSArray *)parsedMethodTypes;
{
    if (hasParsedType == NO) {
        NSError *error = nil;

        CDTypeParser *parser = [[CDTypeParser alloc] initWithType:type];
        parsedMethodTypes = [parser parseMethodType:&error];
        if (parsedMethodTypes == nil)
            NSLog(@"Warning: Parsing method types failed, %@", name);
        hasParsedType = YES;
    }

    return parsedMethodTypes;
}

- (void)appendToString:(NSMutableString *)resultString typeController:(CDTypeController *)typeController symbolReferences:(CDSymbolReferences *)symbolReferences;
{
    NSString *formattedString = [typeController.methodTypeFormatter formatMethodName:name type:type symbolReferences:symbolReferences];
    if (formattedString != nil) {
        [resultString appendString:formattedString];
        [resultString appendString:@";"];
        if (typeController.shouldShowMethodAddresses && imp != 0) {
            if (typeController.targetArchUses64BitABI)
                [resultString appendFormat:@"\t// IMP=0x%016lx", imp];
            else
                [resultString appendFormat:@"\t// IMP=0x%08lx", imp];
        }
    } else
        [resultString appendFormat:@"    // Error parsing type: %@, name: %@", type, name];
}

#pragma mark - Sorting

- (NSComparisonResult)ascendingCompareByName:(CDOCMethod *)otherMethod;
{
    return [name compare:otherMethod.name];
}

@end
