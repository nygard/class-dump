//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2005  Steve Nygard

#import <ObjcUnit/TestCase.h>

@class CDClassDump;

@interface CDStructHandlingUnitTest : TestCase
{
    CDClassDump *classDump;
}

- (void)dealloc;

- (void)setUp;
- (void)tearDown;

- (void)testVariableName:(NSString *)aVariableName type:(NSString *)aType expectedResult:(NSString *)expectedResult;
- (void)registerStructsFromType:(NSString *)aTypeString phase:(int)phase;

- (void)testFilename:(NSString *)testFilename;

#if 0
- (void)test1;
- (void)test2;
- (void)test3;
- (void)test4;
- (void)test5;
- (void)test6;
- (void)test7;
- (void)test8;
- (void)test9;
- (void)test10;
- (void)test11;
#endif

@end
