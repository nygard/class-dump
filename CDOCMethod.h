//
// $Id: CDOCMethod.h,v 1.7 2004/01/06 02:31:42 nygard Exp $
//

//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import <Foundation/NSObject.h>

@class NSMutableString, NSString;
@class CDClassDump2;

@interface CDOCMethod : NSObject
{
    NSString *name;
    NSString *type;
    unsigned long imp;
}

- (id)initWithName:(NSString *)aName type:(NSString *)aType imp:(unsigned long)anImp;
- (void)dealloc;

- (NSString *)name;
- (NSString *)type;
- (unsigned long)imp;

- (NSString *)description;
- (void)appendToString:(NSMutableString *)resultString classDump:(CDClassDump2 *)aClassDump;

- (NSComparisonResult)ascendingCompareByName:(CDOCMethod *)otherMethod;

@end
