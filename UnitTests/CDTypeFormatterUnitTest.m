// This file is part of APPNAME, SHORT DESCRIPTION
// Copyright (C) 2003 Steve Nygard.  All rights reserved.

#import "CDTypeFormatterUnitTest.h"

#import <Foundation/Foundation.h>
#import "CDTypeFormatter.h"

@implementation CDTypeFormatterUnitTest

- (void)setUp;
{
}

- (void)tearDown;
{
}

- (void)testVariableName:(NSString *)aVariableName type:(NSString *)aType expectedResult:(NSString *)expectedResult;
{
    NSString *result;

    result = [CDTypeFormatter formatVariable:aVariableName type:aType atLevel:0];
    [self assert:result equals:expectedResult];
}

- (void)testBasicTypes;
{
    //[self variableName:@"var" testType:@"i" expectedResult:@"int var"];

    [self testVariableName:@"var" type:@"c" expectedResult:@"char var"];
    [self testVariableName:@"var" type:@"i" expectedResult:@"int var"];
    [self testVariableName:@"var" type:@"s" expectedResult:@"short var"];
    [self testVariableName:@"var" type:@"l" expectedResult:@"long var"];
    [self testVariableName:@"var" type:@"q" expectedResult:@"long long var"];
    [self testVariableName:@"var" type:@"C" expectedResult:@"unsigned char var"];
    [self testVariableName:@"var" type:@"I" expectedResult:@"unsigned int var"];
    [self testVariableName:@"var" type:@"S" expectedResult:@"unsigned short var"];
    [self testVariableName:@"var" type:@"L" expectedResult:@"unsigned long var"];
    [self testVariableName:@"var" type:@"Q" expectedResult:@"unsigned long long var"];
    [self testVariableName:@"var" type:@"f" expectedResult:@"float var"];
    [self testVariableName:@"var" type:@"d" expectedResult:@"double var"];
    [self testVariableName:@"var" type:@"B" expectedResult:@"_Bool var"];
    [self testVariableName:@"var" type:@"v" expectedResult:@"void var"]; // TODO: Doesn't make sense
    [self testVariableName:@"var" type:@"*" expectedResult:@"char *var"];
    [self testVariableName:@"var" type:@"#" expectedResult:@"Class var"];
    [self testVariableName:@"var" type:@":" expectedResult:@"SEL var"];
    [self testVariableName:@"var" type:@"%" expectedResult:@"NXAtom var"];
    [self testVariableName:@"var" type:@"?" expectedResult:@"UNKNOWN var"];
}

- (void)testModifiers;
{
    // Hmm, interesting.  These all seem to fail for variables.
    [self testVariableName:@"var" type:@"ri" expectedResult:@"const int var"];
    [self testVariableName:@"var" type:@"ni" expectedResult:@"in int var"];
    [self testVariableName:@"var" type:@"Ni" expectedResult:@"inout int var"];
    [self testVariableName:@"var" type:@"oi" expectedResult:@"out int var"];
    [self testVariableName:@"var" type:@"Oi" expectedResult:@"bycopy int var"];
    [self testVariableName:@"var" type:@"Ri" expectedResult:@"byref int var"];
    [self testVariableName:@"var" type:@"Vi" expectedResult:@"oneway int var"];

    [self testVariableName:@"var" type:@"i" expectedResult:@"int var-it went to the end"];
}

- (void)testPointers;
{
    [self testVariableName:@"var" type:@"^c" expectedResult:@"char *var"];
    [self testVariableName:@"var" type:@"^i" expectedResult:@"int *var"];
    [self testVariableName:@"var" type:@"^s" expectedResult:@"short *var"];
    [self testVariableName:@"var" type:@"^l" expectedResult:@"long *var"];
    [self testVariableName:@"var" type:@"^q" expectedResult:@"long long *var"];
    [self testVariableName:@"var" type:@"^C" expectedResult:@"unsigned char *var"];
    [self testVariableName:@"var" type:@"^I" expectedResult:@"unsigned int *var"];
    [self testVariableName:@"var" type:@"^S" expectedResult:@"unsigned short *var"];
    [self testVariableName:@"var" type:@"^L" expectedResult:@"unsigned long *var"];
    [self testVariableName:@"var" type:@"^Q" expectedResult:@"unsigned long long *var"];
    [self testVariableName:@"var" type:@"^f" expectedResult:@"float *var"];
    [self testVariableName:@"var" type:@"^d" expectedResult:@"double *var"];
    [self testVariableName:@"var" type:@"^B" expectedResult:@"_Bool *var"];
    [self testVariableName:@"var" type:@"^v" expectedResult:@"void *var"]; // TODO: Doesn't make sense
    [self testVariableName:@"var" type:@"^*" expectedResult:@"char **var"];
    [self testVariableName:@"var" type:@"^#" expectedResult:@"Class *var"];
    [self testVariableName:@"var" type:@"^:" expectedResult:@"SEL *var"];
    [self testVariableName:@"var" type:@"^%" expectedResult:@"NXAtom *var"];
    [self testVariableName:@"var" type:@"^?" expectedResult:@"UNKNOWN *var"];

    [self testVariableName:@"var" type:@"^^i" expectedResult:@"int **var"];
}

- (void)testStructType;
{
    //[self testVariableName:@"" type:@"" expectedResult:@""];
    //[self testVariableName:@"" type:@"" expectedResult:@""];
    //[self testVariableName:@"" type:@"" expectedResult:@""];
    //[self testVariableName:@"" type:@"" expectedResult:@""];
    //[self testVariableName:@"" type:@"" expectedResult:@""];
    //[self testVariableName:@"" type:@"" expectedResult:@""];
    //[self testVariableName:@"" type:@"" expectedResult:@""];
}

- (void)testUnionType;
{
    // _tokenBuffer
    [self testVariableName:@"_tokenBuffer" type:@"(?=\"ascii\"*\"unicode\"^S)" expectedResult:@"union ? _tokenBuffer"];
    //[self testVariableName:@"" type:@"" expectedResult:@""];
}

#if 0
- (void)testBar;
{
    // Test for failure.
    [self testVariableName:@"var" type:@"i" expectedResult:@"float var"];
    [self testVariableName:@"var" type:@"*" expectedResult:@"STR var"];
}
#endif

@end
