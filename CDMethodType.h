//
// $Id: CDMethodType.h,v 1.2 2004/01/06 01:51:53 nygard Exp $
//

//  This file is part of class-dump, a utility for exmaing the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

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
