//
// $Id: CDOCSymtab.h,v 1.8 2004/01/15 03:04:53 nygard Exp $
//

//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import <Foundation/NSObject.h>
#import "CDStructRegistrationProtocol.h"

@class NSArray, NSMutableString;
@class CDClassDump2;

@interface CDOCSymtab : NSObject
{
    NSArray *classes;
    NSArray *categories;
}

- (id)init;
- (void)dealloc;

- (NSArray *)classes;
- (void)setClasses:(NSArray *)newClasses;

- (NSArray *)categories;
- (void)setCategories:(NSArray *)newCategories;

- (NSString *)description;

- (void)appendToString:(NSMutableString *)resultString classDump:(CDClassDump2 *)aClassDump;

- (void)registerStructuresWithObject:(id <CDStructRegistration>)anObject phase:(int)phase;

@end
