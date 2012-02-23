// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDType;

@interface CDStructureInfo : NSObject <NSCopying>
{
    CDType *type;
    NSUInteger referenceCount;
    BOOL isUsedInMethod;
    NSString *typedefName;
}

- (id)initWithType:(CDType *)aType;

- (NSString *)description;
- (NSString *)shortDescription;

@property (readonly) CDType *type;

@property (assign) NSUInteger referenceCount;
- (void)addReferenceCount:(NSUInteger)count;

@property (assign) BOOL isUsedInMethod;
@property (retain) NSString *typedefName;

- (void)generateTypedefName:(NSString *)baseName;

- (NSString *)name;

- (NSComparisonResult)ascendingCompareByStructureDepth:(CDStructureInfo *)otherInfo;
- (NSComparisonResult)descendingCompareByStructureDepth:(CDStructureInfo *)otherInfo;

@end
