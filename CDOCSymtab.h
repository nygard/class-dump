//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2006  Steve Nygard

#import <Foundation/NSObject.h>
#import "CDStructureRegistrationProtocol.h"

@class NSArray, NSMutableDictionary, NSMutableString;
@class CDClassDump;

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

- (void)appendToString:(NSMutableString *)resultString classDump:(CDClassDump *)aClassDump;
- (void)generateSeparateHeadersClassDump:(CDClassDump *)aClassDump;

@end
