// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

@class CDOCSymtab;

@interface CDOCModule : NSObject

@property (assign) uint32_t version;
@property (strong) NSString *name;
@property (strong) CDOCSymtab *symtab;

- (NSString *)formattedString;

@end
