//
// $Id: CDOCSymtab.h,v 1.10 2004/02/02 19:46:43 nygard Exp $
//

//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import <Foundation/NSObject.h>
#import "CDStructureRegistrationProtocol.h"

@class NSArray, NSMutableDictionary, NSMutableString;
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

- (void)registerStructuresWithObject:(id <CDStructureRegistration>)anObject phase:(int)phase;
- (void)registerClassesWithObject:(NSMutableDictionary *)aDictionary frameworkName:(NSString *)aFrameworkName;

- (void)appendToString:(NSMutableString *)resultString classDump:(CDClassDump2 *)aClassDump;
- (void)generateSeparateHeadersClassDump:(CDClassDump2 *)aClassDump;

@end
