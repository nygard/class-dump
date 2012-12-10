// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

@class CDType, CDTypeController;

@interface CDOCInstanceVariable : NSObject

- (id)initWithName:(NSString *)name typeString:(NSString *)typeString offset:(NSUInteger)offset;

@property (readonly) NSString *name;
@property (readonly) NSString *typeString;
@property (readonly) NSUInteger offset;

// Lazily parses the typeString.  Returns nil and sets the parseError if parsing failed.  Does not try to parse again in the event of an error.
@property (nonatomic, readonly) CDType *type;
@property (readonly) NSError *parseError;

- (void)appendToString:(NSMutableString *)resultString typeController:(CDTypeController *)typeController;

@end
