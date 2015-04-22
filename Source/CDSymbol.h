// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#include <mach-o/nlist.h>

extern NSString *const ObjCClassSymbolPrefix;

@class CDMachOFile, CDSection, CDLCDylib;

@interface CDSymbol : NSObject

- (id)initWithName:(NSString *)name machOFile:(CDMachOFile *)machOFile nlist32:(struct nlist)nlist32;
- (id)initWithName:(NSString *)name machOFile:(CDMachOFile *)machOFile nlist64:(struct nlist_64)nlist64;

@property (nonatomic, readonly) uint64_t value;
@property (readonly) NSString *name;
@property (nonatomic, readonly) CDSection *section;
@property (nonatomic, readonly) CDLCDylib *dylibLoadCommand;

@property (nonatomic, readonly) BOOL isExternal;
@property (nonatomic, readonly) BOOL isPrivateExternal;
@property (nonatomic, readonly) NSUInteger stab;
@property (nonatomic, readonly) NSUInteger type;
@property (nonatomic, readonly) BOOL isDefined;
@property (nonatomic, readonly) BOOL isAbsolute;
@property (nonatomic, readonly) BOOL isInSection;
@property (nonatomic, readonly) BOOL isPrebound;
@property (nonatomic, readonly) BOOL isIndirect;
@property (nonatomic, readonly) BOOL isCommon;
@property (nonatomic, readonly) BOOL isInTextSection;
@property (nonatomic, readonly) BOOL isInDataSection;
@property (nonatomic, readonly) BOOL isInBssSection;
@property (nonatomic, readonly) NSUInteger referenceType;
@property (nonatomic, readonly) NSString *referenceTypeName;
@property (nonatomic, readonly) NSString *shortTypeDescription;
@property (nonatomic, readonly) NSString *longTypeDescription;

- (NSComparisonResult)compare:(CDSymbol *)other;
- (NSComparisonResult)compareByName:(CDSymbol *)other;

+ (NSString *)classNameFromSymbolName:(NSString *)symbolName;

@end
