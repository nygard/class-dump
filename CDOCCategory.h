//
// $Id: CDOCCategory.h,v 1.6 2004/02/02 23:21:21 nygard Exp $
//

//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import "CDOCProtocol.h"

@class NSArray, NSMutableString, NSString;
@class CDSymbolReferences;

@interface CDOCCategory : CDOCProtocol
{
    NSString *className;
}

- (void)dealloc;

- (NSString *)className;
- (void)setClassName:(NSString *)newClassName;

- (void)appendToString:(NSMutableString *)resultString classDump:(CDClassDump2 *)aClassDump symbolReferences:(CDSymbolReferences *)symbolReferences;

- (NSString *)sortableName;

@end
