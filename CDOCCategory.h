// This file is part of APPNAME, SHORT DESCRIPTION
// Copyright (C) 2003 Steve Nygard.  All rights reserved.

#import <Foundation/NSObject.h>

@class NSArray, NSMutableString, NSString;

@interface CDOCCategory : NSObject
{
    NSString *name;
    NSString *className;
    NSArray *protocols;
    NSArray *classMethods;
    NSArray *instanceMethods;
}

- (id)init;
- (void)dealloc;

- (NSString *)name;
- (void)setName:(NSString *)newName;

- (NSString *)className;
- (void)setClassName:(NSString *)newClassName;

- (NSArray *)protocols;
- (void)setProtocols:(NSArray *)newProtocols;

- (NSArray *)classMethods;
- (void)setClassMethods:(NSArray *)newClassMethods;

- (NSArray *)instanceMethods;
- (void)setInstanceMethods:(NSArray *)newInstanceMethods;

- (NSString *)description;

- (void)appendToString:(NSMutableString *)resultString;
- (void)appendRawMethodsToString:(NSMutableString *)resultString;

- (NSString *)sortableName;
- (NSComparisonResult)ascendingCompareByName:(CDOCCategory *)otherCategory;

@end
