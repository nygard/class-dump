//
// $Id: CDOCModule.h,v 1.8 2004/01/06 02:31:42 nygard Exp $
//

//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import <Foundation/NSObject.h>

@class NSMutableString;
@class CDClassDump2, CDOCSymtab;

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

- (void)appendToString:(NSMutableString *)resultString classDump:(CDClassDump2 *)aClassDump;

@end
