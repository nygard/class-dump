//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2007  Steve Nygard

#import <Foundation/Foundation.h>
#import "CDStructureRegistrationProtocol.h"

@class CDClassDump;
@class CDOCCategory, CDOCClass;

@interface CDOCSymtab : NSObject
{
    NSMutableArray *classes;
    NSMutableArray *categories;
}

- (id)init;
- (void)dealloc;

- (NSArray *)classes;
- (void)addClass:(CDOCClass *)aClass;

- (NSArray *)categories;
- (void)addCategory:(CDOCCategory *)aCategory;

- (NSString *)description;

- (void)registerStructuresWithObject:(id <CDStructureRegistration>)anObject phase:(int)phase;

@end
