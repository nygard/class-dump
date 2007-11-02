// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2007  Steve Nygard

#import <Foundation/NSObject.h>

@class NSArray, NSString;

// A rather clunky way to avoid warnings in CDTopoSortNode.m regarind -retain not implemented by protocols
@protocol CDTopologicalSort <NSObject>
- (NSString *)identifier;
- (NSArray *)dependancies;
@end
