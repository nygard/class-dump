//
// $Id: CDTypeFormatter.h,v 1.14 2004/02/11 01:35:22 nygard Exp $
//

//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import <Foundation/NSObject.h>

@class NSString;
@class CDSymbolReferences, CDType;

@interface CDTypeFormatter : NSObject
{
    BOOL shouldExpand; // But just top level struct, level == 0
    BOOL shouldAutoExpand;
    BOOL shouldShowLexing;
    int baseLevel;

    // Not ideal
    id nonretainedDelegate;
}

- (BOOL)shouldExpand;
- (void)setShouldExpand:(BOOL)newFlag;

- (BOOL)shouldAutoExpand;
- (void)setShouldAutoExpand:(BOOL)newFlag;

- (BOOL)shouldShowLexing;
- (void)setShouldShowLexing:(BOOL)newFlag;

- (int)baseLevel;
- (void)setBaseLevel:(int)newBaseLevel;

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

- (NSString *)_specialCaseVariable:(NSString *)name type:(NSString *)type;
- (NSString *)formatVariable:(NSString *)name type:(NSString *)type symbolReferences:(CDSymbolReferences *)symbolReferences;
- (NSString *)formatMethodName:(NSString *)methodName type:(NSString *)type symbolReferences:(CDSymbolReferences *)symbolReferences;

- (CDType *)replacementForType:(CDType *)aType;
- (NSString *)typedefNameForStruct:(CDType *)structType level:(int)level;

@end
