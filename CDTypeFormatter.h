//
// $Id: CDTypeFormatter.h,v 1.10 2004/01/07 21:26:47 nygard Exp $
//

//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import <Foundation/NSObject.h>

@class NSString;
@class CDType;

@interface CDTypeFormatter : NSObject
{
    BOOL shouldExpand; // But just top level struct, level == 0
    BOOL shouldAutoExpand;
    int baseLevel;

    // Not ideal
    id nonretainedDelegate;
}

//+ (id)sharedTypeFormatter;
//+ (id)sharedIvarTypeFormatter;
//+ (id)sharedMethodTypeFormatter;
//+ (id)sharedStructDeclarationTypeFormatter;

- (BOOL)shouldExpand;
- (void)setShouldExpand:(BOOL)newFlag;

- (BOOL)shouldAutoExpand;
- (void)setShouldAutoExpand:(BOOL)newFlag;

- (int)baseLevel;
- (void)setBaseLevel:(int)newBaseLevel;

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

- (NSString *)_specialCaseVariable:(NSString *)name type:(NSString *)type;
- (NSString *)formatVariable:(NSString *)name type:(NSString *)type;
- (NSString *)formatMethodName:(NSString *)methodName type:(NSString *)type;

- (CDType *)replacementForType:(CDType *)aType;
- (NSString *)typedefNameForStruct:(NSString *)structTypeString;

@end
