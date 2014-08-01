#import <Kiwi/Kiwi.h>

#import "CDSymbolMapper.h"

SPEC_BEGIN(CDSymbolMapperSpec)

describe(@"CDSymbolMapper", ^{
    __block CDSymbolMapper *mapper;

    beforeEach(^{
        mapper = [[CDSymbolMapper alloc] init];
    });

    describe(@"processing crash dump", ^{

        NSString *className = @"TestClass";
        NSString *obfuscatedClass = @"abc";
        NSString *methodName = @"initWithSomething";
        NSString *obfusctedMethodName = @"cde";
        NSString *unknownMethod = @"count";

        NSString *otherClassName = @"TestClass2";
        NSString *otherObfuscatedClass = @"abcd";
        NSString *otherMethodName = @"initWithSomethingElse";
        NSString *otherObfuscatedMethodName = @"cde2";

        NSString *crashDump = [NSString stringWithFormat:@"-[%@ %@:%@:]\n-[%@ %@:]", obfuscatedClass, obfusctedMethodName, unknownMethod, otherObfuscatedClass, otherObfuscatedMethodName];
        NSString *realName = [NSString stringWithFormat:@"-[%@ %@:%@:]\n-[%@ %@:]", className, methodName, unknownMethod, otherClassName, otherMethodName];
        NSDictionary *symbols = @{
                obfuscatedClass : className,
                obfusctedMethodName : methodName,
                otherObfuscatedClass : otherClassName,
                otherObfuscatedMethodName : otherMethodName
        };

        it(@"should replace known symbols", ^{
            NSString *result = [mapper processCrashDump:crashDump withSymbols:symbols];

            [[result shouldNot] beNil];
            NSUInteger classLocation = [result rangeOfString:className].location;
            [[theValue(classLocation) shouldNot] equal:theValue(NSNotFound)];

            NSUInteger methodLocation = [result rangeOfString:methodName].location;
            [[theValue(methodLocation) shouldNot] equal:theValue(NSNotFound)];
        });

        it(@"should not replace unknown symbols", ^{
            NSString *result = [mapper processCrashDump:crashDump withSymbols:symbols];

            [[result shouldNot] beNil];
            NSUInteger classLocation = [result rangeOfString:unknownMethod].location;
            [[theValue(classLocation) shouldNot] equal:theValue(NSNotFound)];
        });

        it(@"should replace all symbols according to the map", ^{
            NSString *result = [mapper processCrashDump:crashDump withSymbols:symbols];

            [[result shouldNot] beNil];
            [[result should] equal:realName];
        });
    });
});

SPEC_END
