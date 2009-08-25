// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import "CDStructureInfo.h"

#import "NSError-CDExtensions.h"
#import "NSString-Extensions.h"
#import "CDType.h"
#import "CDTypeParser.h"

// If it's used in a method, then it should be declared at the top. (name or typedef)

@implementation CDStructureInfo

- (id)initWithTypeString:(NSString *)str;
{
    if ([super init] == nil)
        return nil;

    referenceCount = 1;

    {
        CDTypeParser *parser;
        NSError *error;

        parser = [[CDTypeParser alloc] initWithType:str];
        type = [[parser parseType:&error] retain];
        if (type == nil)
            NSLog(@"Warning: (CDStructInfo) Parsing struct type failed, %@", [error myExplanation]);
        [parser release];
    }

    isUsedInMethod = NO;

    return self;
}

- (void)dealloc;
{
    [type release];

    [super dealloc];
}

- (CDType *)type;
{
    return type;
}

- (NSUInteger)referenceCount;
{
    return referenceCount;
}

- (void)setReferenceCount:(NSUInteger)newCount;
{
    referenceCount = newCount;
}

- (void)addReferenceCount:(NSUInteger)count;
{
    referenceCount += count;
}

- (BOOL)isUsedInMethod;
{
    return isUsedInMethod;
}

- (void)setIsUsedInMethod:(BOOL)newFlag;
{
    isUsedInMethod = newFlag;
}

- (NSString *)typedefName;
{
    return typedefName;
}

- (void)setTypedefName:(NSString *)newName;
{
    if (newName == typedefName)
        return;

    [typedefName release];
    typedefName = [newName retain];
}

// Do this before generating member names.
- (void)generateTypedefName:(NSString *)baseName;
{
    NSString *digest;
    NSUInteger length;

    digest = [[type typeString] SHA1DigestString];
    length = [digest length];
    if (length > 8)
        digest = [digest substringFromIndex:length - 8];

    [self setTypedefName:[NSString stringWithFormat:@"%@%@", baseName, digest]];
    //NSLog(@"typedefName: %@", typedefName);
}

- (NSString *)name;
{
    return [[type typeName] description];
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> depth: %u, refcount: %u, isUsedInMethod: %u, type: %p",
                     NSStringFromClass([self class]), self,
                     [type structureDepth], referenceCount, isUsedInMethod, type];
}

- (NSString *)shortDescription;
{
    return [NSString stringWithFormat:@"%u %u m?%u %@ %@", [type structureDepth], referenceCount, isUsedInMethod, [type bareTypeString], [type typeString]];
}

- (NSComparisonResult)ascendingCompareByStructureDepth:(CDStructureInfo *)otherInfo;
{
    NSUInteger thisDepth, otherDepth;

    thisDepth = [type structureDepth];
    otherDepth = [[otherInfo type] structureDepth];

    if (thisDepth < otherDepth)
        return NSOrderedAscending;
    else if (thisDepth > otherDepth)
        return NSOrderedDescending;

    return [[type typeString] compare:[[otherInfo type] typeString]];
}

- (NSComparisonResult)descendingCompareByStructureDepth:(CDStructureInfo *)otherInfo;
{
    NSUInteger thisDepth, otherDepth;

    thisDepth = [type structureDepth];
    otherDepth = [[otherInfo type] structureDepth];

    if (thisDepth < otherDepth)
        return NSOrderedDescending;
    else if (thisDepth > otherDepth)
        return NSOrderedAscending;

    return [[type typeString] compare:[[otherInfo type] typeString]];
}

- (id)copyWithZone:(NSZone *)zone;
{
    CDStructureInfo *copy;

    copy = [[CDStructureInfo alloc] initWithTypeString:[type typeString]];
    [copy setReferenceCount:referenceCount];
    [copy setIsUsedInMethod:isUsedInMethod];
    [copy setTypedefName:typedefName];

    return copy;
}

@end
