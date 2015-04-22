//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "CDTypeFormatterUnitTest.h"

#import <Foundation/Foundation.h>
#import "NSError-CDExtensions.h"

#import "CDType.h"
#import "CDTypeFormatter.h"
#import "CDTypeLexer.h"
#import "CDTypeParser.h"

@implementation CDTypeFormatterUnitTest

- (void)dealloc;
{
    [typeFormatter release];
    [super dealloc];
}

- (void)setUp;
{
    typeFormatter = [[CDTypeFormatter alloc] init];
}

- (void)tearDown;
{
    [typeFormatter release];
    typeFormatter = nil;
}

- (void)testVariableName:(NSString *)aVariableName type:(NSString *)aType expectedResult:(NSString *)expectedResult;
{
    NSString *result;

    result = [typeFormatter formatVariable:aVariableName type:aType symbolReferences:nil];
    STAssertEqualObjects(expectedResult, result, @"");
}

- (void)parseAndEncodeType:(NSString *)originalType;
{
    CDTypeParser *typeParser;
    CDType *parsedType;
    NSString *reencodedType;
    NSError *error;

    typeParser = [[[CDTypeParser alloc] initWithType:originalType] autorelease];
    STAssertNotNil(typeParser, @"Failed to create parser");

    parsedType = [typeParser parseType:&error];
    STAssertNotNil(parsedType, @"-[CDTypeParser parseType:] error: %@", [error myExplanation]);

    reencodedType = [parsedType typeString];
    STAssertEqualObjects(originalType, reencodedType, @"");
}

- (void)testBasicTypes;
{
    //[self variableName:@"var" testType:@"i" expectedResult:@"int var"];

    [self testVariableName:@"var" type:@"c" expectedResult:@"BOOL var"];
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
    [self testVariableName:@"var" type:@"?" expectedResult:@"void var"];
}

- (void)testModifiers;
{
    // The Distributed Object modifiers (in, inout, out, bycopy, byref, oneway) are only for method parameters/return
    // values, so they will never have a variable name.

    // TODO (2003-12-20): Check whether const makes sense for ivars.
    [self testVariableName:nil type:@"ri" expectedResult:@"const int"];
    [self testVariableName:nil type:@"ni" expectedResult:@"in int"];
    [self testVariableName:nil type:@"Ni" expectedResult:@"inout int"];
    [self testVariableName:nil type:@"oi" expectedResult:@"out int"];
    [self testVariableName:nil type:@"Oi" expectedResult:@"bycopy int"];
    [self testVariableName:nil type:@"Ri" expectedResult:@"byref int"];
    [self testVariableName:nil type:@"Vi" expectedResult:@"oneway int"];

    // These shouldn't happen in practice, but here's how they would be formatted
    [self testVariableName:@"var" type:@"ri" expectedResult:@"const int var"];
    [self testVariableName:@"var" type:@"ni" expectedResult:@"in int var"];
    [self testVariableName:@"var" type:@"Ni" expectedResult:@"inout int var"];
    [self testVariableName:@"var" type:@"oi" expectedResult:@"out int var"];
    [self testVariableName:@"var" type:@"Oi" expectedResult:@"bycopy int var"];
    [self testVariableName:@"var" type:@"Ri" expectedResult:@"byref int var"];
    [self testVariableName:@"var" type:@"Vi" expectedResult:@"oneway int var"];

    [self testVariableName:@"var" type:@"^i" expectedResult:@"int *var"];
    [self testVariableName:@"var" type:@"r^i" expectedResult:@"const int *var"];
    [self testVariableName:nil type:@"r^i" expectedResult:@"const int *"];
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
    [self testVariableName:@"var" type:@"^v" expectedResult:@"void *var"];
    [self testVariableName:@"var" type:@"^*" expectedResult:@"char **var"];
    [self testVariableName:@"var" type:@"^#" expectedResult:@"Class *var"];
    [self testVariableName:@"var" type:@"^:" expectedResult:@"SEL *var"];
    [self testVariableName:@"var" type:@"^%" expectedResult:@"NXAtom *var"];
    [self testVariableName:@"var" type:@"^?" expectedResult:@"void *var"];

    [self testVariableName:@"var" type:@"^^i" expectedResult:@"int **var"];
}

- (void)testBitfield;
{
    [self testVariableName:@"var" type:@"b0" expectedResult:@"unsigned int var:0"];
    [self testVariableName:@"var" type:@"b1" expectedResult:@"unsigned int var:1"];
    [self testVariableName:@"var" type:@"b19" expectedResult:@"unsigned int var:19"];
    [self testVariableName:@"var" type:@"b31" expectedResult:@"unsigned int var:31"];
    [self testVariableName:@"var" type:@"b32" expectedResult:@"unsigned int var:32"];
    [self testVariableName:@"var" type:@"b33" expectedResult:@"unsigned int var:33"];
    [self testVariableName:@"var" type:@"b63" expectedResult:@"unsigned int var:63"];
    [self testVariableName:@"var" type:@"b64" expectedResult:@"unsigned int var:64"];
    [self testVariableName:@"var" type:@"b65" expectedResult:@"unsigned int var:65"];
    [self testVariableName:nil type:@"b3" expectedResult:@"unsigned int :3"];

    [self testVariableName:@"var" type:@"b" expectedResult:@"unsigned int var:(null)"]; // Don't we always expect a number?
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
}

- (void)testStructType;
{
    //[self testVariableName:@"var" type:@"{}" expectedResult:@""];
    [self testVariableName:@"var" type:@"{?}" expectedResult:@"struct var"]; // expected, but not correct.  Test these in struct/union handling unit tests
    [self testVariableName:@"var" type:@"{NSStreamFunctions}" expectedResult:@"struct NSStreamFunctions var"];
    [self testVariableName:@"var" type:@"{__ssFlags=\"delegateLearnsWords\"b1\"delegateForgetsWords\"b1\"busy\"b1\"_reserved\"b29}" expectedResult:@"struct __ssFlags var"];
}

- (void)testUnionType;
{
    [self testVariableName:@"_tokenBuffer" type:@"(?=\"ascii\"*\"unicode\"^S)" expectedResult:@"union _tokenBuffer"]; // expected, but not correct.  Test these in struct/union handling unit tests
}

// I have diagrams of these cases
- (void)testDiagrammedTypes;
{
    [self testVariableName:@"foo" type:@"i" expectedResult:@"int foo"];
    [self testVariableName:@"foo" type:@"^i" expectedResult:@"int *foo"];
    [self testVariableName:@"foo" type:@"^^i" expectedResult:@"int **foo"];
    [self testVariableName:@"foo" type:@"[8i]" expectedResult:@"int foo[8]"];
    [self testVariableName:@"foo" type:@"[8^i]" expectedResult:@"int *foo[8]"];
    [self testVariableName:@"foo" type:@"^[8i]" expectedResult:@"int (*foo)[8]"];
    [self testVariableName:@"foo" type:@"[8[12i]]" expectedResult:@"int foo[8][12]"];
    [self testVariableName:@"foo" type:@"^^[8i]" expectedResult:@"int (**foo)[8]"];
    [self testVariableName:@"foo" type:@"^^[8[12i]]" expectedResult:@"int (**foo)[8][12]"];
    [self testVariableName:@"foo" type:@"[3^^[8i]]" expectedResult:@"int (**foo[3])[8]"];
    [self testVariableName:@"foo" type:@"@" expectedResult:@"id foo"];
    [self testVariableName:@"foo" type:@"@\"NSString\"" expectedResult:@"NSString *foo"];
    [self testVariableName:@"foo" type:@"b7" expectedResult:@"unsigned int foo:7"];
    [self testVariableName:@"foo" type:@"r^i" expectedResult:@"const int *foo"];
    //[self testVariableName:@"foo" type:@"" expectedResult:@""];
}

- (void)testErrors;
{
    [self testVariableName:@"bar" type:@"[5i" expectedResult:nil];
    [self testVariableName:@"bar" type:@"" expectedResult:nil];
    [self testVariableName:@"bar" type:nil expectedResult:nil];
}

#if 0
- (void)testBar;
{
    // Test for failure.
    [self testVariableName:@"var" type:@"i" expectedResult:@"float var"];
    [self testVariableName:@"var" type:@"*" expectedResult:@"STR var"];
}
#endif

- (void)testEncoding;
{
    [self parseAndEncodeType:@"c"];
    [self parseAndEncodeType:@"i"];
    [self parseAndEncodeType:@"s"];
    [self parseAndEncodeType:@"l"];
    [self parseAndEncodeType:@"q"];
    [self parseAndEncodeType:@"C"];
    [self parseAndEncodeType:@"I"];
    [self parseAndEncodeType:@"S"];
    [self parseAndEncodeType:@"L"];
    [self parseAndEncodeType:@"Q"];
    [self parseAndEncodeType:@"f"];
    [self parseAndEncodeType:@"d"];
    [self parseAndEncodeType:@"B"];
    [self parseAndEncodeType:@"v"];
    //[self parseAndEncodeType:@"*"];
    [self parseAndEncodeType:@"#"];
    [self parseAndEncodeType:@":"];
    [self parseAndEncodeType:@"%"];
    [self parseAndEncodeType:@"?"];

    [self parseAndEncodeType:@"ri"];
    [self parseAndEncodeType:@"ni"];
    [self parseAndEncodeType:@"Ni"];
    [self parseAndEncodeType:@"oi"];
    [self parseAndEncodeType:@"Oi"];
    [self parseAndEncodeType:@"Ri"];
    [self parseAndEncodeType:@"Vi"];

    [self parseAndEncodeType:@"^i"];
    [self parseAndEncodeType:@"r^i"];

    [self parseAndEncodeType:@"^c"];
    [self parseAndEncodeType:@"^i"];
    [self parseAndEncodeType:@"^s"];
    [self parseAndEncodeType:@"^l"];
    [self parseAndEncodeType:@"^q"];
    [self parseAndEncodeType:@"^C"];
    [self parseAndEncodeType:@"^I"];
    [self parseAndEncodeType:@"^S"];
    [self parseAndEncodeType:@"^L"];
    [self parseAndEncodeType:@"^Q"];
    [self parseAndEncodeType:@"^f"];
    [self parseAndEncodeType:@"^d"];
    [self parseAndEncodeType:@"^B"];
    [self parseAndEncodeType:@"^v"];
    //[self parseAndEncodeType:@"^*"];
    [self parseAndEncodeType:@"^#"];
    [self parseAndEncodeType:@"^:"];
    [self parseAndEncodeType:@"^%"];
    [self parseAndEncodeType:@"^?"];

    [self parseAndEncodeType:@"^^i"];
    [self parseAndEncodeType:@"b0"];
    [self parseAndEncodeType:@"b1"];
    //[self parseAndEncodeType:@"b"];

    [self parseAndEncodeType:@"[0c]"];
    [self parseAndEncodeType:@"[16c]"];
    [self parseAndEncodeType:@"[16^i]"];
    [self parseAndEncodeType:@"^[16i]"];
    [self parseAndEncodeType:@"[16^^i]"];
    [self parseAndEncodeType:@"^^[16i]"];
    [self parseAndEncodeType:@"^[16^i]"];
    [self parseAndEncodeType:@"[8[12f]]"];

    [self parseAndEncodeType:@"{?}"];
    [self parseAndEncodeType:@"{NSStreamFunctions}"];
    [self parseAndEncodeType:@"{__ssFlags=\"delegateLearnsWords\"b1\"delegateForgetsWords\"b1\"busy\"b1\"_reserved\"b29}"];
    [self parseAndEncodeType:@"(?=\"ascii\"^s\"unicode\"^S)"];

    [self parseAndEncodeType:@"i"];
    [self parseAndEncodeType:@"^i"];
    [self parseAndEncodeType:@"^^i"];
    [self parseAndEncodeType:@"[8i]"];
    [self parseAndEncodeType:@"[8^i]"];
    [self parseAndEncodeType:@"^[8i]"];
    [self parseAndEncodeType:@"[8[12i]]"];
    [self parseAndEncodeType:@"^^[8i]"];
    [self parseAndEncodeType:@"^^[8[12i]]"];
    [self parseAndEncodeType:@"[3^^[8i]]"];
    [self parseAndEncodeType:@"@"];
    [self parseAndEncodeType:@"@\"NSString\""];
    [self parseAndEncodeType:@"b7"];
    [self parseAndEncodeType:@"r^i"];

    //[self parseAndEncodeType:@""];
}

- (void)testTemplateTypes;
{
    [self testVariableName:@"var" type:@"r" expectedResult:@"const var"];

    [self testVariableName:@"var" type:@"{KWQRefPtr<KWQValueListImpl::KWQValueListPrivate>=^{KWQValueListPrivate}}"
          expectedResult:@"struct KWQRefPtr<KWQValueListImpl::KWQValueListPrivate> var"];

    [self testVariableName:@"var" type:@"{QValueList<foo<bar>,foo<baz>,bar<blegga>>=i}"
          expectedResult:@"struct QValueList<foo<bar>, foo<baz>, bar<blegga>> var"];
    [self testVariableName:@"var" type:@"{QValueList<KWQSlot<foobar>>=i}" expectedResult:@"struct QValueList<KWQSlot<foobar>> var"];
    [self testVariableName:@"var" type:@"{QValueList<KWQSlot>=i}" expectedResult:@"struct QValueList<KWQSlot> var"];
    [self testVariableName:@"var"
          type:@"{QValueList<KWQSlot>={KWQValueListImpl={KWQRefPtr<KWQValueListImpl::KWQValueListPrivate>=^{KWQValueListPrivate}}}}"
          expectedResult:@"struct QValueList<KWQSlot> var"];
    [self testVariableName:@"var" type:@"{KWQSignal=^{QObject}^{KWQSignal}*{QValueList<KWQSlot>={KWQValueListImpl={KWQRefPtr<KWQValueListImpl::KWQValueListPrivate>=^{KWQValueListPrivate}}}}}" expectedResult:@"struct KWQSignal var"];
    [self testVariableName:@"var" type:@"^{QButton={KWQSignal=^{QObject}^{KWQSignal}*{QValueList<KWQSlot>={KWQValueListImpl={KWQRefPtr<KWQValueListImpl::KWQValueListPrivate>=^{KWQValueListPrivate}}}}}}" expectedResult:@"struct QButton *var"];

    [self testVariableName:@"var" type:@"{std::pair<const double, int>=i}" expectedResult:@"struct std::pair<const double, int> var"];
}

- (void)testIdProtocolTypes;
{
    [self testVariableName:@"var" type:@"@" expectedResult:@"id var"];
    [self testVariableName:@"var" type:@"@\"NSObject\"" expectedResult:@"NSObject *var"];
    [self testVariableName:@"var" type:@"@\"<MyProtocol>\"" expectedResult:@"id <MyProtocol> var"];
    [self testVariableName:@"var" type:@"@\"<MyProtocol1,MyProtocol2>\"" expectedResult:@"id <MyProtocol1, MyProtocol2> var"];
}

- (void)testPages08;
{
    // Pages '08 has this bit in it: {vector<<unnamed>::AnimationChunk,std::allocator<<unnamed>::AnimationChunk> >=II}

    [self testVariableName:@"var" type:@"{unnamed=II}" expectedResult:@"struct unnamed var"];
    [self testVariableName:@"var" type:@"{vector<unnamed>=II}" expectedResult:@"struct vector<unnamed> var"];
    [self testVariableName:@"var" type:@"{vector<unnamed::blegga>=II}" expectedResult:@"struct vector<unnamed::blegga> var"];
    [self testVariableName:@"var" type:@"{vector<<unnamed>::blegga>=II}" expectedResult:@"struct vector<unnamed::blegga> var"];
    [self testVariableName:@"var" type:@"{vector<<unnamed>::AnimationChunk>=II}" expectedResult:@"struct vector<unnamed::AnimationChunk> var"];
    [self testVariableName:@"var" type:@"{vector<<unnamed>::AnimationChunk,std::allocator<<unnamed>::AnimationChunk> >=II}"
          expectedResult:@"struct vector<unnamed::AnimationChunk, std::allocator<unnamed::AnimationChunk>> var"];
}


@end
