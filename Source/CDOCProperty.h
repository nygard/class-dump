// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

@class CDType;

@interface CDOCProperty : NSObject

- (id)initWithName:(NSString *)name attributes:(NSString *)attributes;

@property (readonly) NSString *name;
@property (readonly) NSString *attributeString;
@property (readonly) CDType *type;
@property (readonly) NSArray *attributes;

@property (strong) NSString *attributeStringAfterType;

@property (nonatomic, readonly) NSString *defaultGetter;
@property (nonatomic, readonly) NSString *defaultSetter;

@property (strong) NSString *customGetter;
@property (strong) NSString *customSetter;

@property (nonatomic, readonly) NSString *getter;
@property (nonatomic, readonly) NSString *setter;

@property (readonly) BOOL isReadOnly;
@property (readonly) BOOL isDynamic;

- (NSComparisonResult)ascendingCompareByName:(CDOCProperty *)other;

@end
