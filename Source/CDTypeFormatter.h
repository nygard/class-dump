// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDType, CDTypeController;

@interface CDTypeFormatter : NSObject

@property (weak) CDTypeController *typeController;

@property (assign) NSUInteger baseLevel;
@property (assign) BOOL shouldExpand;
@property (assign) BOOL shouldAutoExpand;
@property (assign) BOOL shouldShowLexing;

- (NSString *)formatVariable:(NSString *)name type:(NSString *)type; // Just used by CDOCIvar
- (NSString *)formatVariable:(NSString *)name parsedType:(CDType *)type;
- (NSString *)formatMethodName:(NSString *)name type:(NSString *)type;

- (NSString *)typedefNameForStruct:(CDType *)structType level:(NSUInteger)level;

- (void)formattingDidReferenceClassName:(NSString *)name;

@end
