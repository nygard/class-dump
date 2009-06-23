// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2009 Steve Nygard.

#import <Foundation/NSObject.h>

@class NSArray, NSMutableSet, NSMutableString, NSString;

@interface CDSymbolReferences : NSObject
{
    NSDictionary *frameworkNamesByClassName;
    NSDictionary *frameworkNamesByProtocolName;

    NSMutableSet *classes;
    NSMutableSet *protocols;
}

- (id)init;
- (void)dealloc;

- (void)setFrameworkNamesByClassName:(NSDictionary *)newValue;
- (void)setFrameworkNamesByProtocolName:(NSDictionary *)newValue;

- (NSString *)frameworkForClassName:(NSString *)aClassName;
- (NSString *)frameworkForProtocolName:(NSString *)aProtocolName;

- (NSArray *)classes;
- (void)addClassName:(NSString *)aClassName;
- (void)removeClassName:(NSString *)aClassName;

- (NSArray *)protocols;
- (void)addProtocolName:(NSString *)aProtocolName;
- (void)addProtocolNamesFromArray:(NSArray *)protocolNames;

- (NSString *)description;

- (void)_appendToString:(NSMutableString *)resultString;
- (NSString *)referenceString;

- (void)removeAllReferences;
- (NSString *)importStringForClassName:(NSString *)aClassName;
- (NSString *)importStringForProtocolName:(NSString *)aProtocolName;

@end
