// This file is part of APPNAME, SHORT DESCRIPTION
// Copyright (C) 2003 Steve Nygard.  All rights reserved.

#import <ObjcUnit/TestCase.h>

@interface CDTypeFormatterUnitTest : TestCase
{
}

- (void)setUp;
- (void)tearDown;

- (void)testVariableName:(NSString *)aVariableName type:(NSString *)aType expectedResult:(NSString *)expectedResult;
- (void)testBasicTypes;
- (void)testModifiers;
- (void)testPointers;
- (void)testStructType;
- (void)testUnionType;
//- (void)testBar;

@end
