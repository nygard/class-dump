// This file is part of APPNAME, SHORT DESCRIPTION
// Copyright (C) 2003 Steve Nygard.  All rights reserved.

#import "CDStructHandlingUnitTest.h"

#import <Foundation/Foundation.h>
#import "CDClassDump.h"
#import "CDType.h"
#import "CDTypeFormatter.h"
#import "CDTypeParser.h"

@implementation CDStructHandlingUnitTest

- (void)dealloc;
{
    [classDump release];

    [super dealloc];
}

- (void)setUp;
{
    classDump = [[CDClassDump2 alloc] init];
}

- (void)tearDown;
{
    [classDump release];
    classDump = nil;
}

- (void)testVariableName:(NSString *)aVariableName type:(NSString *)aType expectedResult:(NSString *)expectedResult;
{
    NSString *result;

    result = [[classDump ivarTypeFormatter] formatVariable:aVariableName type:aType];
    [self assert:result equals:expectedResult];
}

- (void)registerStructsFromType:(NSString *)aTypeString;
{
    CDTypeParser *parser;
    CDType *type;

    parser = [[CDTypeParser alloc] initWithType:aTypeString];
    type = [parser parseType];
    [type registerStructsWithObject:classDump];
    [parser release];
}

- (void)testOne;
{
    NSString *first = @"{_NSRange=II}";

    [self assertNotNil:classDump message:@"classDump"];
    [self assertNotNil:[classDump ivarTypeFormatter] message:@"[classDump ivarTypeFormatter]"];

    [self registerStructsFromType:first];
    [self testVariableName:@"foo" type:first expectedResult:@"    struct _NSRange foo"];

    // Register {_NSRange=II}
    // Test {_NSRange=II}
}

- (void)testTwo;
{
    NSString *first = @"{_NSRange=II}";
    NSString *second = @"{_NSRange=\"location\"I\"length\"I}";

    [self registerStructsFromType:first];
    [self registerStructsFromType:second];
    [self testVariableName:@"foo" type:first expectedResult:@"    struct _NSRange foo"];
    [self testVariableName:@"bar" type:second expectedResult:@"    struct _NSRange bar"];

    // Register {_NSRange=II}
    // Register {_NSRange="location"I"length"I}
    // Test {_NSRange=II}
    // Test {_NSRange="location"I"length"I}
}

- (void)testThree;
{
    NSString *first = @"{_NSRange=\"location\"I\"length\"I}";
    NSString *second = @"{_NSRange=II}";

    [self registerStructsFromType:first];
    [self registerStructsFromType:second];
    [self testVariableName:@"foo" type:first expectedResult:@"    struct _NSRange foo"];
    [self testVariableName:@"bar" type:second expectedResult:@"    struct _NSRange bar"];

    // Register {_NSRange="location"I"length"I}
    // Register {_NSRange=II}
    // Test {_NSRange="location"I"length"I}
    // Test {_NSRange=II}
}

@end
