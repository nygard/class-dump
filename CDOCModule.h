//
// $Id: CDOCModule.h,v 1.10 2004/02/03 22:51:52 nygard Exp $
//

//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import <Foundation/NSObject.h>

@class NSMutableDictionary, NSMutableString;
@class CDClassDump, CDOCSymtab;

@interface CDOCModule : NSObject
{
    unsigned long version;
    //unsigned long size; // Not really relevant here
    NSString *name;
    CDOCSymtab *symtab;
}

- (id)init;
- (void)dealloc;

- (unsigned long)version;
- (void)setVersion:(unsigned long)aVersion;

- (NSString *)name;
- (void)setName:(NSString *)newName;

- (CDOCSymtab *)symtab;
- (void)setSymtab:(CDOCSymtab *)newSymtab;

- (NSString *)description;
- (NSString *)formattedString;

- (void)appendToString:(NSMutableString *)resultString classDump:(CDClassDump *)aClassDump;
- (void)registerClassesWithObject:(NSMutableDictionary *)aDictionary frameworkName:(NSString *)aFrameworkName;
- (void)generateSeparateHeadersClassDump:(CDClassDump *)aClassDump;

@end
