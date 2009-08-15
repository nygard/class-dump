// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDType;

@interface CDStructureInfo : NSObject <NSCopying>
{
    NSString *typeString;
    NSUInteger referenceCount;
    CDType *type;
    BOOL isUsedInMethod;
}

// TODO: Or just pass in type?
- (id)initWithTypeString:(NSString *)str;
- (void)dealloc;

- (NSString *)typeString;
- (CDType *)type;

- (NSUInteger)referenceCount;
- (void)setReferenceCount:(NSUInteger)newCount;
- (void)addReferenceCount:(NSUInteger)count;

- (BOOL)isUsedInMethod;
- (void)setIsUsedInMethod:(BOOL)newFlag;

- (NSString *)description;
- (NSString *)shortDescription;

- (NSComparisonResult)ascendingCompareByStructureDepth:(CDStructureInfo *)otherInfo;
- (NSComparisonResult)descendingCompareByStructureDepth:(CDStructureInfo *)otherInfo;

- (id)copyWithZone:(NSZone *)zone;

@end
