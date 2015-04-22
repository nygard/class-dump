// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

@class CDType;

@interface CDStructureInfo : NSObject <NSCopying>

- (id)initWithType:(CDType *)type;

- (NSString *)shortDescription;

@property (readonly) CDType *type;

@property (assign) NSUInteger referenceCount;
- (void)addReferenceCount:(NSUInteger)count;

@property (assign) BOOL isUsedInMethod;
@property (strong) NSString *typedefName;

- (void)generateTypedefName:(NSString *)baseName;

@property (nonatomic, readonly) NSString *name;

- (NSComparisonResult)ascendingCompareByStructureDepth:(CDStructureInfo *)other;
- (NSComparisonResult)descendingCompareByStructureDepth:(CDStructureInfo *)other;

@end
