// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

@class CDType, CDTypeController;

@interface CDOCInstanceVariable : NSObject

- (id)initWithName:(NSString *)name typeString:(NSString *)typeString offset:(NSUInteger)offset;

@property (readonly) NSString *name;
@property (readonly) NSString *typeString;
@property (readonly) NSUInteger offset;

@property (nonatomic, readonly) CDType *parsedType;

- (void)appendToString:(NSMutableString *)resultString typeController:(CDTypeController *)typeController;

@end
