// This file is part of APPNAME, SHORT DESCRIPTION
// Copyright (C) 2003 Steve Nygard.  All rights reserved.

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

@end
