// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import <Foundation/Foundation.h>

@interface CDSymbolReferences : NSObject

@property (strong) NSDictionary *frameworkNamesByClassName;    // NSString (class name)    -> NSString (framework name)
@property (strong) NSDictionary *frameworkNamesByProtocolName; // NSString (protocol name) -> NSString (framework name)

- (NSString *)frameworkForClassName:(NSString *)className;
- (NSString *)frameworkForProtocolName:(NSString *)protocolName;

- (void)addClassName:(NSString *)className;
- (void)removeClassName:(NSString *)className;

- (void)addProtocolName:(NSString *)protocolName;
- (void)addProtocolNamesFromArray:(NSArray *)protocolNames;

@property (nonatomic, readonly) NSString *referenceString;

- (void)removeAllReferences;
- (NSString *)importStringForClassName:(NSString *)className;
- (NSString *)importStringForProtocolName:(NSString *)protocolName;

@end
