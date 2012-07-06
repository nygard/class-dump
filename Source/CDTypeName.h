// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import <Foundation/Foundation.h>

@interface CDTypeName : NSObject <NSCopying>

@property (strong) NSString *name;
@property (readonly) NSMutableArray *templateTypes;
@property (strong) NSString *suffix;
@property (readonly) BOOL isTemplateType;

@end
