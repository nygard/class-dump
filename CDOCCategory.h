// This file is part of APPNAME, SHORT DESCRIPTION
// Copyright (C) 2003 Steve Nygard.  All rights reserved.

#import "CDOCProtocol.h"

@class NSArray, NSMutableString, NSString;

@interface CDOCCategory : CDOCProtocol
{
    NSString *className;
}

- (void)dealloc;

- (NSString *)className;
- (void)setClassName:(NSString *)newClassName;

- (void)appendToString:(NSMutableString *)resultString;

- (NSString *)sortableName;

@end
