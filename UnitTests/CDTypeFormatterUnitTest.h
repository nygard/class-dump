// This file is part of APPNAME, SHORT DESCRIPTION
// Copyright (C) 2003 Steve Nygard.  All rights reserved.

#import <ObjcUnit/TestCase.h>

@class CDTypeFormatter;

@interface CDTypeFormatterUnitTest : TestCase
{
    CDTypeFormatter *typeFormatter;
}

- (void)dealloc;

- (void)setUp;
- (void)tearDown;

- (void)testVariableName:(NSString *)aVariableName type:(NSString *)aType expectedResult:(NSString *)expectedResult;
- (void)testBasicTypes;
- (void)testModifiers;
- (void)testPointers;
- (void)testBitfield;
- (void)testArrayType;
- (void)testStructType;
- (void)testUnionType;
- (void)testDiagrammedTypes;
- (void)testErrors;
//- (void)testBar;

- (void)parseAndEncodeType:(NSString *)originalType;
- (void)testEncoding;

@end
