// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDClassDump, CDOCSymtab;

@interface CDOCModule : NSObject
{
    uint32_t version;
    NSString *name;
    CDOCSymtab *symtab;
}

- (id)init;
- (void)dealloc;

- (uint32_t)version;
- (void)setVersion:(uint32_t)aVersion;

- (NSString *)name;
- (void)setName:(NSString *)newName;

- (CDOCSymtab *)symtab;
- (void)setSymtab:(CDOCSymtab *)newSymtab;

- (NSString *)description;
- (NSString *)formattedString;

@end
