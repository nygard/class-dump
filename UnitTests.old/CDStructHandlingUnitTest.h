// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import <SenTestingKit/SenTestingKit.h>

@class CDClassDump;

@interface CDStructHandlingUnitTest : SenTestCase
{
    CDClassDump *classDump;
}

- (void)dealloc;

- (void)setUp;
- (void)tearDown;

- (void)testVariableName:(NSString *)aVariableName type:(NSString *)aType expectedResult:(NSString *)expectedResult;
- (void)registerStructsFromType:(NSString *)aTypeString phase:(int)phase;

- (void)testFilename:(NSString *)testFilename;

@end
