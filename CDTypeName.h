// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import <Foundation/Foundation.h>

@interface CDTypeName : NSObject
{
    NSString *name;
    NSMutableArray *templateTypes;
    NSString *suffix;
}

- (id)init;
- (void)dealloc;

- (NSString *)name;
- (void)setName:(NSString *)newName;

- (NSArray *)templateTypes;
- (void)addTemplateType:(CDTypeName *)aTemplateType;

- (NSString *)suffix;
- (void)setSuffix:(NSString *)newSuffix;

- (NSString *)description;

- (BOOL)isTemplateType;

- (BOOL)isEqual:(id)otherObject;

@end
