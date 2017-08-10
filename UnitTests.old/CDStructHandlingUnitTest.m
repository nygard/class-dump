//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDStructHandlingUnitTest.h"

#import <Foundation/Foundation.h>
#import "NSError-CDExtensions.h"

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
    classDump = [[CDClassDump alloc] init];
}

- (void)tearDown;
{
    [classDump release];
    classDump = nil;
}

- (void)testVariableName:(NSString *)aVariableName type:(NSString *)aType expectedResult:(NSString *)expectedResult;
{
    NSString *result;

    result = [[classDump ivarTypeFormatter] formatVariable:aVariableName type:aType symbolReferences:nil];
    STAssertEqualObjects(expectedResult, result, @"");
}

- (void)registerStructsFromType:(NSString *)aTypeString phase:(int)phase;
{
    CDTypeParser *parser;
    CDType *type;
    NSError *error;

    parser = [[CDTypeParser alloc] initWithType:aTypeString];
    type = [parser parseType:&error];
    STAssertNotNil(type, @"-[CDTypeParser parseType:] error: %@", [error myExplanation]);

    [type phase:phase registerStructuresWithObject:classDump usedInMethod:NO];
    [parser release];
}

// TODO (2004-01-05): Move this somewhere that we can share it with the main app.
- (void)testFilename:(NSString *)testFilename;
{
    NSString *inputFilename, *outputFilename;
    NSMutableString *resultString;
    NSString *inputContents, *expectedOutputContents;
    NSArray *inputLines, *inputFields;
    int phase;
    int count, index;
    NSBundle *bundle;

    //NSLog(@"***** %@", testFilename);

    resultString = [NSMutableString string];

    bundle = [NSBundle bundleForClass:[self class]];
    inputFilename = [bundle pathForResource:[testFilename stringByAppendingString:@"-in"] ofType:@"txt"];
    outputFilename = [bundle pathForResource:[testFilename stringByAppendingString:@"-out"] ofType:@"txt"];

    inputContents = [NSString stringWithContentsOfFile:inputFilename];
    expectedOutputContents = [NSString stringWithContentsOfFile:outputFilename];

    inputLines = [inputContents componentsSeparatedByString:@"\n"];
    count = [inputLines count];

    // First register structs/unions
    for (phase = 1; phase <= 2; phase++) {
        //NSLog(@"Phase %d ========================================", phase);

        for (index = 0; index < count; index++) {
            NSString *line;

            line = [inputLines objectAtIndex:index];
            if ([line length] > 0 && [line hasPrefix:@"//"] == NO) {
                inputFields = [line componentsSeparatedByString:@"\t"];
                [self registerStructsFromType:[inputFields objectAtIndex:0] phase:phase];
            }
        }

        [classDump endPhase:phase];
    }

    // Then generate output
    [classDump appendStructuresToString:resultString symbolReferences:nil];

    for (index = 0; index < count; index++) {
        NSString *line;
        NSString *type, *variableName;

        line = [inputLines objectAtIndex:index];
        if ([line length] > 0 && [line hasPrefix:@"//"] == NO) {
            int fieldCount, level;
            NSString *formattedString;

            inputFields = [line componentsSeparatedByString:@"\t"];
            fieldCount = [inputFields count];
            type = [inputFields objectAtIndex:0];
            if (fieldCount > 1)
                variableName = [inputFields objectAtIndex:1];
            else
                variableName = @"var";

            if (fieldCount > 2)
                level = [[inputFields objectAtIndex:2] intValue];
            else
                level = 0;

            formattedString = [[classDump ivarTypeFormatter] formatVariable:variableName type:type symbolReferences:nil];
            if (formattedString != nil) {
                [resultString appendString:formattedString];
                [resultString appendString:@";\n"];
            } else {
                [resultString appendString:@"Parse failed.\n"];
            }
        }
    }

    STAssertEqualObjects(expectedOutputContents, resultString, @"test file: %@", testFilename);
}

#if 1
- (void)test01;
{
    NSString *first = @"{_NSRange=II}";
    int phase;

    STAssertNotNil(classDump, @"classDump");
    STAssertNotNil([classDump ivarTypeFormatter], @"[classDump ivarTypeFormatter]");

    for (phase = 1; phase <= 2; phase++)
        [self registerStructsFromType:first phase:phase];
    [self testVariableName:@"foo" type:first expectedResult:@"    struct _NSRange foo"];

    // Register {_NSRange=II}
    // Test {_NSRange=II}
}

- (void)test02;
{
    NSString *first = @"{_NSRange=II}";
    NSString *second = @"{_NSRange=\"location\"I\"length\"I}";
    int phase;

    for (phase = 1; phase <= 2; phase++) {
        [self registerStructsFromType:first phase:phase];
        [self registerStructsFromType:second phase:phase];
    }

    [self testVariableName:@"foo" type:first expectedResult:@"    struct _NSRange foo"];
    [self testVariableName:@"bar" type:second expectedResult:@"    struct _NSRange bar"];

    // Register {_NSRange=II}
    // Register {_NSRange="location"I"length"I}
    // Test {_NSRange=II}
    // Test {_NSRange="location"I"length"I}
}

- (void)test03;
{
    NSString *first = @"{_NSRange=\"location\"I\"length\"I}";
    NSString *second = @"{_NSRange=II}";
    int phase;

    for (phase = 1; phase <= 2; phase++) {
        [self registerStructsFromType:first phase:phase];
        [self registerStructsFromType:second phase:phase];
    }

    [self testVariableName:@"foo" type:first expectedResult:@"    struct _NSRange foo"];
    [self testVariableName:@"bar" type:second expectedResult:@"    struct _NSRange bar"];

    // Register {_NSRange="location"I"length"I}
    // Register {_NSRange=II}
    // Test {_NSRange="location"I"length"I}
    // Test {_NSRange=II}
}

- (void)test04;
{
    // I'm guessing that "shud" could stand for Struct Handling Unittest Data.
    [self testFilename:@"shud01"];
}

- (void)test05;
{
    [self testFilename:@"shud02"];
}

- (void)test06;
{
    //[self testFilename:@"shud03"];
}

- (void)test07;
{
    [self testFilename:@"shud04"];
}

- (void)test08;
{
    [self testFilename:@"shud05"];
}

- (void)test09;
{
    [self testFilename:@"shud06"];
}

- (void)test10;
{
    [self testFilename:@"shud07"];
}

- (void)test11;
{
    [self testFilename:@"shud08"];
}

- (void)test12;
{
    [self testFilename:@"shud09"];
}

- (void)test13;
{
    [self testFilename:@"shud10"];
}

- (void)test14;
{
    [self testFilename:@"shud11"];
}
#endif

- (void)test15;
{
    [self testFilename:@"shud13"];
}

- (void)test16;
{
    //[self testFilename:@"shud14"];
}

// This tests the new code for dealing with named objects and field names in structures.
- (void)test17;
{
    [self testFilename:@"shud15"];
}

- (void)test18;
{
    [self testFilename:@"shud16"];
}

@end
