//  This file is part of class-dump, a utility for examining the
//  Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2005  Steve Nygard

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

- (void)test1;

@end
