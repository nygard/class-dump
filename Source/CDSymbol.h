// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import <Foundation/Foundation.h>

#include <mach-o/nlist.h>

extern NSString *const ObjCClassSymbolPrefix;

@class CDMachOFile, CDSection, CDLCDylib;

@interface CDSymbol : NSObject

- (id)initWithName:(NSString *)aName machOFile:(CDMachOFile *)aMachOFile nlist32:(struct nlist)nlist32;
- (id)initWithName:(NSString *)aName machOFile:(CDMachOFile *)aMachOFile nlist64:(struct nlist_64)nlist64;

- (NSString *)description;

@property (readonly) uint64_t value;
@property (readonly) NSString *name;
@property (nonatomic, readonly) CDSection *section;
@property (nonatomic, readonly) CDLCDylib *dylibLoadCommand;

@property (readonly) BOOL isExternal;
@property (readonly) BOOL isPrivateExternal;
@property (readonly) NSUInteger stab;
@property (readonly) NSUInteger type;
@property (readonly) BOOL isUndefined;
@property (readonly) BOOL isAbsolute;
@property (readonly) BOOL isInSection;
@property (readonly) BOOL isPrebound;
@property (readonly) BOOL isIndirect;
@property (readonly) BOOL isCommon;
@property (readonly) BOOL isInTextSection;
@property (readonly) BOOL isInDataSection;
@property (readonly) BOOL isInBssSection;
@property (readonly) NSUInteger referenceType;
@property (nonatomic, readonly) NSString *referenceTypeName;
@property (nonatomic, readonly) NSString *shortTypeDescription;
@property (nonatomic, readonly) NSString *longTypeDescription;

- (NSComparisonResult)compare:(CDSymbol *)aSymbol;
- (NSComparisonResult)nameCompare:(CDSymbol *)aSymbol;

@end
