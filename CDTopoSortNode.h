//
// $Id: CDTopoSortNode.h,v 1.3 2004/01/06 02:31:43 nygard Exp $
//

//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

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
