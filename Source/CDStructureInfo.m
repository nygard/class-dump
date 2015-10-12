// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

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
    CDStructureInfo *copy = [[CDStructureInfo alloc] initWithType:self.type]; // type gets copied
    copy.referenceCount = self.referenceCount;
    copy.isUsedInMethod = self.isUsedInMethod;
    copy.typedefName = self.typedefName;
    
    return copy;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> depth: %lu, refcount: %lu, isUsedInMethod: %u, type: %p",
            NSStringFromClass([self class]), self,
            self.type.structureDepth, self.referenceCount, self.isUsedInMethod, self.type];
}

- (NSString *)shortDescription;
{
    return [NSString stringWithFormat:@"%lu %lu m?%u %@ %@", self.type.structureDepth, self.referenceCount, self.isUsedInMethod, self.type.bareTypeString, self.type.typeString];
}

#pragma mark -

- (void)addReferenceCount:(NSUInteger)count;
{
    self.referenceCount += count;
}

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
- (NSComparisonResult)ascendingCompareByStructureDepth:(CDStructureInfo *)other;
{
    NSUInteger thisDepth = self.type.structureDepth;
    NSUInteger otherDepth = other.type.structureDepth;

    if (thisDepth < otherDepth) return NSOrderedAscending;
    if (thisDepth > otherDepth) return NSOrderedDescending;

    NSString *str1 = self.type.reallyBareTypeString;
    NSString *str2 = other.type.reallyBareTypeString;
    NSComparisonResult result = [str1 compare:str2];
    if (result == NSOrderedSame) {
        str1 = self.type.typeString;
        str2 = other.type.typeString;
        result = [str1 compare:str2];
    }

    return result;
}

- (NSComparisonResult)descendingCompareByStructureDepth:(CDStructureInfo *)other;
{
    NSUInteger thisDepth = self.type.structureDepth;
    NSUInteger otherDepth = other.type.structureDepth;

    if (thisDepth < otherDepth) return NSOrderedDescending;
    if (thisDepth > otherDepth) return NSOrderedAscending;

    NSString *str1 = self.type.reallyBareTypeString;
    NSString *str2 = other.type.reallyBareTypeString;
    NSComparisonResult result = -[str1 compare:str2];
    if (result == NSOrderedSame) {
        str1 = self.type.typeString;
        str2 = other.type.typeString;
        result = -[str1 compare:str2];
    }

    return result;
}

@end
