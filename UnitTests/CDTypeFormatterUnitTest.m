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
    // The Distributed Object modifiers (in, inout, out, bycopy, byref, oneway) are only for method paramters/return
    // values, so they will never have a variable name.

    // TODO (2003-12-20): Check whether const makes sense for ivars.
    [self testVariableName:nil type:@"ri" expectedResult:@"const int"];
    [self testVariableName:nil type:@"ni" expectedResult:@"in int"];
    [self testVariableName:nil type:@"Ni" expectedResult:@"inout int"];
    [self testVariableName:nil type:@"oi" expectedResult:@"out int"];
    [self testVariableName:nil type:@"Oi" expectedResult:@"bycopy int"];
    [self testVariableName:nil type:@"Ri" expectedResult:@"byref int"];
    [self testVariableName:nil type:@"Vi" expectedResult:@"oneway int"];

    //[self testVariableName:nil type:@"r^i" expectedResult:@"const int *var"];
    //[self testVariableName:nil type:@"^ri" expectedResult:@"int *const"];
    //[self testVariableName:nil type:@"r^ri" expectedResult:@"const int *const"];

    //[self testVariableName:nil type:@"i" expectedResult:@"int var-it went to the end"];
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

- (void)testBitfield;
{
    [self testVariableName:@"var" type:@"b0" expectedResult:@"int var:0"];
    [self testVariableName:@"var" type:@"b1" expectedResult:@"int var:1"];
    [self testVariableName:@"var" type:@"b19" expectedResult:@"int var:19"];
    [self testVariableName:@"var" type:@"b31" expectedResult:@"int var:31"];
    [self testVariableName:@"var" type:@"b32" expectedResult:@"int var:32"];
    [self testVariableName:@"var" type:@"b33" expectedResult:@"int var:33"];
    [self testVariableName:@"var" type:@"b63" expectedResult:@"int var:63"];
    [self testVariableName:@"var" type:@"b64" expectedResult:@"int var:64"];
    [self testVariableName:@"var" type:@"b65" expectedResult:@"int var:65"];

    [self testVariableName:@"var" type:@"b" expectedResult:@"int var:(null)"]; // Don't we always expect a number?
}

- (void)testArrayType;
{
    [self testVariableName:@"var" type:@"[0c]" expectedResult:@"char var[0]"];
    [self testVariableName:@"var" type:@"[1c]" expectedResult:@"char var[1]"];
    [self testVariableName:@"var" type:@"[16c]" expectedResult:@"char var[16]"];

    [self testVariableName:@"var" type:@"[16^i]" expectedResult:@"int *var[16]"];
    [self testVariableName:@"var" type:@"^[16i]" expectedResult:@"int (*var)[16]"];
    [self testVariableName:@"var" type:@"[16^^i]" expectedResult:@"int **var[16]"];
    [self testVariableName:@"var" type:@"^^[16i]" expectedResult:@"int (**var)[16]"];
    [self testVariableName:@"var" type:@"^[16^i]" expectedResult:@"int *(*var)[16]"];

    [self testVariableName:@"var" type:@"[8[12f]]" expectedResult:@"float var[8][12]"];
    //[self testVariableName:@"var" type:@"[8b3]" expectedResult:@"int var:3[8]"]; // Don't know if this is even valid!

    //[self testVariableName:@"var" type:@"" expectedResult:@""];
    //[self testVariableName:@"var" type:@"" expectedResult:@""];
    //[self testVariableName:@"var" type:@"" expectedResult:@""];
    //[self testVariableName:@"var" type:@"" expectedResult:@""];
    //[self testVariableName:@"var" type:@"" expectedResult:@""];
    //[self testVariableName:@"var" type:@"" expectedResult:@""];
    //[self testVariableName:@"var" type:@"" expectedResult:@""];
    //[self testVariableName:@"var" type:@"" expectedResult:@""];
    //[self testVariableName:@"var" type:@"" expectedResult:@""];
    //[self testVariableName:@"var" type:@"" expectedResult:@""];
    //[self testVariableName:@"var" type:@"" expectedResult:@""];
    //[self testVariableName:@"var" type:@"" expectedResult:@""];
    //[self testVariableName:@"var" type:@"" expectedResult:@""];
    //[self testVariableName:@"var" type:@"" expectedResult:@""];
    //[self testVariableName:@"var" type:@"" expectedResult:@""];
    //[self testVariableName:@"var" type:@"" expectedResult:@""];
    //[self testVariableName:@"var" type:@"" expectedResult:@""];
}

- (void)testStructType;
{
    //[self testVariableName:@"var" type:@"{}" expectedResult:@""];
    [self testVariableName:@"var" type:@"{?}" expectedResult:@"struct ? var"];
    [self testVariableName:@"var" type:@"{NSStreamFunctions}" expectedResult:@"struct NSStreamFunctions var"];
    [self testVariableName:@"var" type:@"{__ssFlags=\"delegateLearnsWords\"b1\"delegateForgetsWords\"b1\"busy\"b1\"_reserved\"b29}" expectedResult:@"struct __ssFlags var"];
    //[self testVariableName:@"" type:@"" expectedResult:@""];
    //[self testVariableName:@"" type:@"" expectedResult:@""];
    //[self testVariableName:@"" type:@"" expectedResult:@""];
}

- (void)testUnionType;
{
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
