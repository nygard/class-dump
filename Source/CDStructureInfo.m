// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDStructureInfo.h"

#import "CDType.h"
#import "CDTypeName.h"

// If it's used in a method, then it should be declared at the top. (name or typedef)

@implementation CDStructureInfo
{
    CDType *_type;
    NSUInteger _referenceCount;
    BOOL _isUsedInMethod;
    NSString *_typedefName;
}

- (id)initWithType:(CDType *)type;
{
    if ((self = [super init])) {
        _type = [type copy];
        _referenceCount = 1;
        _isUsedInMethod = NO;
        _typedefName = nil;
    }

    return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone;
{
    CDStructureInfo *copy = [[CDStructureInfo allocWithZone:zone] initWithType:self.type]; // type gets copied
    copy.referenceCount = self.referenceCount;
    copy.isUsedInMethod = self.isUsedInMethod;
    copy.typedefName = self.typedefName;
    
    return copy;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> depth: %u, refcount: %u, isUsedInMethod: %u, type: %p",
            NSStringFromClass([self class]), self,
            self.type.structureDepth, self.referenceCount, self.isUsedInMethod, self.type];
}

- (NSString *)shortDescription;
{
    return [NSString stringWithFormat:@"%u %u m?%u %@ %@", self.type.structureDepth, self.referenceCount, self.isUsedInMethod, self.type.bareTypeString, self.type.typeString];
}

#pragma mark -

@synthesize type = _type;
@synthesize referenceCount = _referenceCount;

- (void)addReferenceCount:(NSUInteger)count;
{
    self.referenceCount += count;
}

@synthesize isUsedInMethod = _isUsedInMethod;
@synthesize typedefName = _typedefName;

// Do this before generating member names.
- (void)generateTypedefName:(NSString *)baseName;
{
    NSString *digest = [self.type.typeString SHA1DigestString];
    NSUInteger length = [digest length];
    if (length > 8)
        digest = [digest substringFromIndex:length - 8];

    self.typedefName = [NSString stringWithFormat:@"%@%@", baseName, digest];
    //NSLog(@"typedefName: %@", self.typedefName);
}

- (NSString *)name;
{
    return [self.type.typeName description];
}

#pragma mark - Sorting

// Structure depth, reallyBareTypeString, typeString
- (NSComparisonResult)ascendingCompareByStructureDepth:(CDStructureInfo *)otherInfo;
{
    NSUInteger thisDepth = self.type.structureDepth;
    NSUInteger otherDepth = otherInfo.type.structureDepth;

    if (thisDepth < otherDepth)
        return NSOrderedAscending;
    else if (thisDepth > otherDepth)
        return NSOrderedDescending;

    NSString *str1 = self.type.reallyBareTypeString;
    NSString *str2 = otherInfo.type.reallyBareTypeString;
    NSComparisonResult result = [str1 compare:str2];
    if (result == NSOrderedSame) {
        str1 = self.type.typeString;
        str2 = otherInfo.type.typeString;
        result = [str1 compare:str2];
    }

    return result;
}

- (NSComparisonResult)descendingCompareByStructureDepth:(CDStructureInfo *)otherInfo;
{
    NSUInteger thisDepth = self.type.structureDepth;
    NSUInteger otherDepth = otherInfo.type.structureDepth;

    if (thisDepth < otherDepth)
        return NSOrderedDescending;
    else if (thisDepth > otherDepth)
        return NSOrderedAscending;

    NSString *str1 = self.type.reallyBareTypeString;
    NSString *str2 = otherInfo.type.reallyBareTypeString;
    NSComparisonResult result = -[str1 compare:str2];
    if (result == NSOrderedSame) {
        str1 = self.type.typeString;
        str2 = otherInfo.type.typeString;
        result = -[str1 compare:str2];
    }

    return result;
}

@end
