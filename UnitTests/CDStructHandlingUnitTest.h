//
// $Id: CDStructHandlingUnitTest.h,v 1.4 2004/01/06 01:52:00 nygard Exp $
//

//  This file is part of class-dump, a utility for exmaing the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard

#import <ObjcUnit/TestCase.h>

@class CDClassDump2;

@interface CDStructHandlingUnitTest : TestCase
{
    CDClassDump2 *classDump;
}

- (void)dealloc;

- (void)setUp;
- (void)tearDown;

- (void)testVariableName:(NSString *)aVariableName type:(NSString *)aType expectedResult:(NSString *)expectedResult;
- (void)registerStructsFromType:(NSString *)aTypeString;

- (void)testFilename:(NSString *)testFilename;

- (void)testOne;
- (void)testTwo;
- (void)testThree;

- (void)testFour;
- (void)testFive;
- (void)testSix;

@end
