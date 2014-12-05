#import <Kiwi/Kiwi.h>

#import "CDSymbolsGeneratorVisitor.h"
#import "CDOCProperty.h"
#import "NSString-CDExtensions.h"
#import "CDOCMethod.h"

SPEC_BEGIN(CDSymoblsGeneratorVisitorSpec)

    describe(@"CDSymbolsGeneratorVisitor", ^{
        __block CDSymbolsGeneratorVisitor *visitor;

        beforeEach(^{
            visitor = [[CDSymbolsGeneratorVisitor alloc] init];
        });

        describe(@"visiting property", ^{

            NSString *propertyName = @"propertyName";
            CDOCProperty *aProperty = [[CDOCProperty alloc] initWithName:propertyName attributes:@""];

            context(@"when obfuscating plain property", ^{
                it(@"should generate symbol for default getter", ^{
                    [visitor willBeginVisiting];

                    [visitor visitProperty:aProperty];
    
                    [visitor didEndVisiting];

                    [[visitor.symbols[propertyName] shouldNot] beNil];
                });
    
                it(@"should generate symbol for default setter", ^{
                    [visitor willBeginVisiting];

                    [visitor visitProperty:aProperty];
    
                    [visitor didEndVisiting];

                    NSString *setterName = [NSString stringWithFormat:@"set%@", [propertyName capitalizeFirstCharacter]];
                    [[visitor.symbols[setterName] shouldNot] beNil];
                });
    
                it(@"should generate symbol for iVar", ^{
                    [visitor willBeginVisiting];

                    [visitor visitProperty:aProperty];
    
                    [visitor didEndVisiting];
    
                    NSString *ivarName = [NSString stringWithFormat:@"_%@", propertyName];
                    [[visitor.symbols[ivarName] shouldNot] beNil];
                });
    
                it(@"should generate symbol for 'is' property getter", ^{
                    [visitor willBeginVisiting];

                    [visitor visitProperty:aProperty];
    
                    [visitor didEndVisiting];
    
                    NSString *isGetterName = [NSString stringWithFormat:@"is%@", [propertyName capitalizeFirstCharacter]];
                    [[visitor.symbols[isGetterName] shouldNot] beNil];
                });
    
    
                it(@"should generate symbol for 'setIs' setter", ^{
                    [visitor willBeginVisiting];
    
                    [visitor visitProperty:aProperty];
    
                    [visitor didEndVisiting];
    
                    NSString *setterName = [NSString stringWithFormat:@"setIs%@", [propertyName capitalizeFirstCharacter]];
                    [[visitor.symbols[setterName] shouldNot] beNil];
                });
    
                it(@"should generate symbol for 'setIs' iVar", ^{
                    [visitor willBeginVisiting];
    
                    [visitor visitProperty:aProperty];
    
                    [visitor didEndVisiting];
    
                    NSString *ivarIsName = [NSString stringWithFormat:@"_is%@", [propertyName capitalizeFirstCharacter]];
                    [[visitor.symbols[ivarIsName] shouldNot] beNil];
                });

                context(@"when obfuscating setter for upprecase property", ^{
                    NSString *uppercaseName = @"HTTPBody";
                    CDOCProperty *upperCaseProperty = [[CDOCProperty alloc] initWithName:uppercaseName attributes:@""];
                    it(@"should not change first letter to lowercase", ^{
                        [visitor willBeginVisiting];

                        [visitor visitProperty:upperCaseProperty];

                        [visitor didEndVisiting];

                        NSString *symbolName = visitor.symbols[[uppercaseName lowercaseFirstCharacter]];
                        [[symbolName should] beNil];
                    });
                });

                context(@"when obfuscating getter for upprecase property", ^{
                    NSString *uppercaseName = @"HTTPBody";
                    CDOCProperty *upperCaseProperty = [[CDOCProperty alloc] initWithName:uppercaseName attributes:@""];
                    it(@"should not change first letter to lowercase", ^{
                        [visitor willBeginVisiting];

                        [visitor visitProperty:upperCaseProperty];

                        [visitor didEndVisiting];

                        NSString *symbolName = visitor.symbols[[uppercaseName lowercaseFirstCharacter]];
                        [[symbolName should] beNil];
                    });
                });
            });

            context(@"when obfuscating 'is' property", ^{
                CDOCProperty *isProperty = [[CDOCProperty alloc] initWithName:[@"is" stringByAppendingString:[propertyName capitalizeFirstCharacter]] attributes:@""];

                it(@"should generate symbol for default getter", ^{
                    [visitor willBeginVisiting];

                    [visitor visitProperty:isProperty];

                    [visitor didEndVisiting];

                    [[visitor.symbols[propertyName] shouldNot] beNil];
                });

                it(@"should generate symbol for default setter", ^{
                    [visitor willBeginVisiting];

                    [visitor visitProperty:isProperty];

                    [visitor didEndVisiting];

                    NSString *setterName = [NSString stringWithFormat:@"set%@", [propertyName capitalizeFirstCharacter]];
                    [[visitor.symbols[setterName] shouldNot] beNil];
                });

                it(@"should generate symbol for iVar", ^{
                    [visitor willBeginVisiting];

                    [visitor visitProperty:isProperty];

                    [visitor didEndVisiting];

                    NSString *ivarName = [NSString stringWithFormat:@"_%@", propertyName];
                    [[visitor.symbols[ivarName] shouldNot] beNil];
                });

                it(@"should generate symbol for 'is' property getter", ^{
                    [visitor willBeginVisiting];

                    [visitor visitProperty:isProperty];

                    [visitor didEndVisiting];

                    NSString *isGetterName = [NSString stringWithFormat:@"is%@", [propertyName capitalizeFirstCharacter]];
                    [[visitor.symbols[isGetterName] shouldNot] beNil];
                });


                it(@"should generate symbol for 'setIs' setter for 'is' property", ^{
                    [visitor willBeginVisiting];

                    [visitor visitProperty:isProperty];

                    [visitor didEndVisiting];

                    NSString *setterName = [NSString stringWithFormat:@"setIs%@", [propertyName capitalizeFirstCharacter]];
                    [[visitor.symbols[setterName] shouldNot] beNil];
                });

                it(@"should generate symbol for '_is' ivar for 'is' property", ^{
                    [visitor willBeginVisiting];

                    [visitor visitProperty:isProperty];

                    [visitor didEndVisiting];

                    NSString *ivarName = [NSString stringWithFormat:@"_is%@", [propertyName capitalizeFirstCharacter]];
                    [[visitor.symbols[ivarName] shouldNot] beNil];
                });

                context(@"when obfuscating setter for uppercase property", ^{
                    NSString *uppercaseName = @"HTTPBody";
                    CDOCProperty *upperCaseProperty = [[CDOCProperty alloc] initWithName:[@"is" stringByAppendingString:uppercaseName] attributes:@""];
                    it(@"should not change first letter to lowercase", ^{
                        [visitor willBeginVisiting];

                        [visitor visitProperty:upperCaseProperty];

                        [visitor didEndVisiting];

                        NSString *symbol = visitor.symbols[[uppercaseName lowercaseFirstCharacter]];
                        [[symbol should] beNil];
                    });
                });
            });
        });

        describe(@"visiting method", ^{
            NSString *methodName = @"methodName";
            __block CDOCMethod *method;

            beforeEach(^{
                method = [[CDOCMethod alloc] initWithName:methodName typeString:@""];
            });

            it(@"should generate symbol for method", ^{
                [visitor willBeginVisiting];

                [visitor visitInstanceMethod:method propertyState:nil];

                [visitor didEndVisiting];

                [[visitor.symbols[methodName] shouldNot] beNil];
            });

            context(@"when method is a setter", ^{
                beforeEach(^{
                    method = [[CDOCMethod alloc] initWithName:[@"set" stringByAppendingString:[methodName capitalizeFirstCharacter]] typeString:nil];
                });

                it(@"should generate symbol for getter", ^{
                    [visitor willBeginVisiting];

                    [visitor visitInstanceMethod:method propertyState:nil];

                    [visitor didEndVisiting];

                    [[visitor.symbols[methodName] shouldNot] beNil];
                });

                context(@"for uppercase getter name", ^{
                    NSString *uppercaseName = @"HTTPBody";
                    CDOCMethod *upperCaseProperty = [[CDOCMethod alloc] initWithName:[@"set" stringByAppendingString:uppercaseName] typeString:nil];
                    it(@"should not change first letter to lowercase", ^{
                        [visitor willBeginVisiting];

                        [visitor visitInstanceMethod:upperCaseProperty propertyState:nil];

                        [visitor didEndVisiting];

                        NSString *symbol = visitor.symbols[[uppercaseName lowercaseFirstCharacter]];
                        [[symbol should] beNil];
                    });
                });
            });

            context(@"when method is a getter", ^{
                beforeEach(^{
                    method = [[CDOCMethod alloc] initWithName:methodName typeString:nil];
                });

                it(@"should generate symbol for setter", ^{
                    [visitor willBeginVisiting];

                    [visitor visitInstanceMethod:method propertyState:nil];

                    [visitor didEndVisiting];

                    NSString *setterName = [NSString stringWithFormat:@"set%@", [methodName capitalizeFirstCharacter]];
                    [[visitor.symbols[setterName] shouldNot] beNil];
                });
            });

            context(@"when obfuscating method which name starts with 'set'", ^{
                NSString *setupName = @"setupSomething";

                beforeEach(^{
                    method = [[CDOCMethod alloc] initWithName:setupName typeString:nil];
                });

                it(@"should generate symbol name for whole word", ^{
                    [visitor willBeginVisiting];

                    [visitor visitInstanceMethod:method propertyState:nil];

                    [visitor didEndVisiting];

                    NSString *symbol = visitor.symbols[setupName];
                    [[symbol shouldNot] beNil];
                    [[theValue([symbol hasPrefix:@"set"]) should] beFalse];
                });
            });

            context(@"when obfuscating method signature is longer than obfuscated one", ^{
                __block NSString *originalSignature = @"somethingLong";

                beforeEach(^{
                    method = [[CDOCMethod alloc] initWithName:originalSignature typeString:nil];
                });

                it(@"should set padding to make obfuscated signature's length equal original one's length", ^{
                    [visitor willBeginVisiting];

                    [visitor visitInstanceMethod:method propertyState:nil];

                    [visitor didEndVisiting];

                    [visitor addSymbolsPadding];

                    NSString *symbol = visitor.symbols[originalSignature];
                    [[symbol shouldNot] beNil];
                    [[theValue(symbol.length) should] equal:theValue(originalSignature.length)];
                });
            });
        });
    });

SPEC_END
