// This file is part of APPNAME, SHORT DESCRIPTION
// Copyright (C) 2003 Steve Nygard.  All rights reserved.

#import <Foundation/NSObject.h>

@class NSArray, NSMutableSet, NSString;

@interface CDTopoSortNode : NSObject
{
    NSString *identifier;
    NSMutableSet *dependancies;
}

- (id)initWithIdentifier:(NSString *)anIdentifier;
- (void)dealloc;

- (NSString *)identifier;

- (NSArray *)dependancies;
- (void)addDependancy:(NSString *)anIdentifier;
- (void)removeDependancy:(NSString *)anIdentifier;
- (void)addDependanciesFromArray:(NSArray *)identifiers;

@end
