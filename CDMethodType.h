// This file is part of APPNAME, SHORT DESCRIPTION
// Copyright (C) 2003 Steve Nygard.  All rights reserved.

#import <Foundation/NSObject.h>

@class NSMutableArray;
@class CDType;

@interface CDMethodType : NSObject
{
    CDType *type;
    NSString *offset;
}

- (id)initWithType:(CDType *)aType offset:(NSString *)anOffset;
- (void)dealloc;

- (CDType *)type;
- (NSString *)offset;

- (NSString *)description;

@end
