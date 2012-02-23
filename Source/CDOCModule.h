// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDClassDump, CDOCSymtab;

@interface CDOCModule : NSObject

- (NSString *)description;

@property (assign) uint32_t version;
@property (retain) NSString *name;
@property (retain) CDOCSymtab *symtab;

- (NSString *)formattedString;

@end
