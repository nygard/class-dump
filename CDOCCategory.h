//
// $Id: CDOCCategory.h,v 1.5 2004/01/06 02:31:41 nygard Exp $
//

//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import "CDOCProtocol.h"

@class NSArray, NSMutableString, NSString;

@interface CDOCCategory : CDOCProtocol
{
    NSString *className;
}

- (void)dealloc;

- (NSString *)className;
- (void)setClassName:(NSString *)newClassName;

- (void)appendToString:(NSMutableString *)resultString classDump:(CDClassDump2 *)aClassDump;

- (NSString *)sortableName;

@end
