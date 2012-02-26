// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import <Foundation/Foundation.h>

// 1. Record which frameworks reference classes.
// 2. Provide the appropriate framework name for a class, to be used to generate #imports -- i.e. #import <Foundation/NSArray.h>

@interface CDSymbolReferences : NSObject

// Build up the data.  Used by CDClassFrameworkVisitor.
- (void)addClassName:(NSString *)name referencedInFramework:(NSString *)framework;

- (NSString *)frameworkForClassName:(NSString *)className;





- (void)addClassName:(NSString *)className;
- (void)removeClassName:(NSString *)className;

- (void)addProtocolNamesFromArray:(NSArray *)protocolNames;

@property (nonatomic, readonly) NSString *referenceString;

- (void)removeAllReferences;
- (NSString *)importStringForClassName:(NSString *)className;

@end
