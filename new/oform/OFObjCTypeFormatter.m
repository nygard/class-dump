#import "OFObjCTypeFormatter.h"

#import <Foundation/Foundation.h>

@implementation OFObjCTypeFormatter

+ (NSString *)formattedType:(NSString *)type forIvar:(NSString *)name;
{
    return nil;
}

+ (BOOL)verifyType:(NSString *)type forIvar:(NSString *)name expectedResult:(NSString *)expectedResult;
{
    NSString *formattedType;
    BOOL isCorrect;

    formattedType = [self formattedType:type forIvar:name];
    isCorrect = [formattedType isEqual:expectedResult];
    if (isCorrect == NO) {
        NSLog(@"formatted ivar ('%@', '%@') = '%@' != '%@'", type, name, formattedType, expectedResult);
    }

    return isCorrect;
}

+ (void)test;
{
    NSLog(@"Testing....");
    [self verifyType:@"c" forIvar:@"foo" expectedResult:@"char foo"];
    [self verifyType:@"i" forIvar:@"foo" expectedResult:@"int foo"];
    [self verifyType:@"s" forIvar:@"foo" expectedResult:@"short foo"];
    [self verifyType:@"l" forIvar:@"foo" expectedResult:@"long foo"];
    [self verifyType:@"q" forIvar:@"foo" expectedResult:@"long long foo"];

    [self verifyType:@"C" forIvar:@"foo" expectedResult:@"unsigned char foo"];
    [self verifyType:@"I" forIvar:@"foo" expectedResult:@"unsigned int foo"];
    [self verifyType:@"S" forIvar:@"foo" expectedResult:@"unsigned short foo"];
    [self verifyType:@"L" forIvar:@"foo" expectedResult:@"unsigned long foo"];
    [self verifyType:@"Q" forIvar:@"foo" expectedResult:@"unsigned long long foo"];

    [self verifyType:@"f" forIvar:@"foo" expectedResult:@"float foo"];
    [self verifyType:@"d" forIvar:@"foo" expectedResult:@"double foo"];
    [self verifyType:@"v" forIvar:@"foo" expectedResult:@"void foo"]; // Doesn't make sense
    [self verifyType:@"*" forIvar:@"foo" expectedResult:@"char *foo"]; // Preprocess into ^* ?
    [self verifyType:@"@" forIvar:@"foo" expectedResult:@"id foo"];
    [self verifyType:@"#" forIvar:@"foo" expectedResult:@"Class foo"];
    [self verifyType:@":" forIvar:@"foo" expectedResult:@"SEL foo"];

    //[self verifyType:@"" forIvar:@"foo" expectedResult:@""];
}

@end
