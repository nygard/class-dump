// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2011 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDType;

@interface CDMethodType : NSObject
{
    CDType *type;
    NSString *offset;
}

- (id)initWithType:(CDType *)aType offset:(NSString *)anOffset;

- (NSString *)description;

@property (readonly) CDType *type;
@property (readonly) NSString *offset;

@end
