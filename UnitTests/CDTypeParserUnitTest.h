//
// $Id: CDTypeParserUnitTest.h,v 1.3 2004/01/18 02:30:08 nygard Exp $
//

//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import <ObjcUnit/TestCase.h>

@interface CDTypeParserUnitTest : TestCase
{
}

- (void)setUp;
- (void)tearDown;

- (void)testMethodType:(NSString *)aMethodType showLexing:(BOOL)shouldShowLexing;

@end
