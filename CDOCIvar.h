//
// $Id: CDOCIvar.h,v 1.6 2004/01/06 01:51:54 nygard Exp $
//

//  This file is part of class-dump, a utility for exmaing the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import <Foundation/NSObject.h>

@class NSMutableString, NSString;
@class CDClassDump2;

@interface CDOCIvar : NSObject
{
    NSString *name;
    NSString *type;
    int offset;
}

- (id)initWithName:(NSString *)aName type:(NSString *)aType offset:(int)anOffset;
- (void)dealloc;

- (NSString *)name;
- (NSString *)type;
- (int)offset;

- (NSString *)description;
- (void)appendToString:(NSMutableString *)resultString classDump:(CDClassDump2 *)aClassDump;

@end
