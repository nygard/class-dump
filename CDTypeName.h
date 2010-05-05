// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2010 Steve Nygard.

#import <Foundation/Foundation.h>

@interface CDTypeName : NSObject <NSCopying>
{
    NSString *name;
    NSMutableArray *templateTypes;
    NSString *suffix;
}

- (id)init;
- (void)dealloc;

@property(retain) NSString *name;

- (NSArray *)templateTypes;
- (void)addTemplateType:(CDTypeName *)aTemplateType;

@property(retain) NSString *suffix;

- (NSString *)description;

- (BOOL)isTemplateType;

- (BOOL)isEqual:(id)otherObject;

- (id)copyWithZone:(NSZone *)zone;

@end
