#import <Kiwi/Kiwi.h>

#import "CDSymoblsGeneratorVisitor.h"
#import "CDOCProperty.h"
#import "NSString-CDExtensions.h"
#import "CDOCMethod.h"

SPEC_BEGIN(CDSymoblsGeneratorVisitorSpec)

    describe(@"CDSymoblsGeneratorVisitor", ^{
        __block CDSymoblsGeneratorVisitor *visitor;

        beforeEach(^{
            visitor = [[CDSymoblsGeneratorVisitor alloc] init];
        });

        describe(@"visiting property", ^{

            NSString *propertyName = @"propertyName";
            CDOCProperty *aProperty = [[CDOCProperty alloc] initWithName:propertyName attributes:@""];

            context(@"when obfuscating plain property", ^{
                it(@"should generate symbol for default getter", ^{
                    [visitor willBeginVisiting];

                    [visitor visitProperty:aProperty];
    
                    [visitor didEndVisiting];
    
                    NSInteger location = [visitor.resultString rangeOfString:[NSString stringWithFormat:@"#define %@", propertyName]].location;
                    [[theValue(location) shouldNot] equal:theValue(NSNotFound)];
                });
    
                it(@"should generate symbol for default setter", ^{
                    [visitor willBeginVisiting];

                    [visitor visitProperty:aProperty];
    
                    [visitor didEndVisiting];
    
                    NSInteger location = [visitor.resultString rangeOfString:[NSString stringWithFormat:@"#define set%@", [propertyName capitalizeFirstCharacter]]].location;
                    [[theValue(location) shouldNot] equal:theValue(NSNotFound)];
                });
    
                it(@"should generate symbol for iVar", ^{
                    [visitor willBeginVisiting];

                    [visitor visitProperty:aProperty];
    
                    [visitor didEndVisiting];
    
                    NSInteger location = [visitor.resultString rangeOfString:[NSString stringWithFormat:@"#define _%@", propertyName]].location;
                    [[theValue(location) shouldNot] equal:theValue(NSNotFound)];
                });
    
                it(@"should generate symbol for 'is' property getter", ^{
                    [visitor willBeginVisiting];

                    [visitor visitProperty:aProperty];
    
                    [visitor didEndVisiting];
    
                    NSInteger location = [visitor.resultString rangeOfString:[NSString stringWithFormat:@"#define is%@", [propertyName capitalizeFirstCharacter]]].location;
                    [[theValue(location) shouldNot] equal:theValue(NSNotFound)];
                });
    
    
                it(@"should generate symbol for 'setIs' setter", ^{
                    [visitor willBeginVisiting];
    
                    [visitor visitProperty:aProperty];
    
                    [visitor didEndVisiting];
    
                    NSInteger location = [visitor.resultString rangeOfString:[NSString stringWithFormat:@"#define setIs%@", [propertyName capitalizeFirstCharacter]]].location;
                    [[theValue(location) shouldNot] equal:theValue(NSNotFound)];
                });
    
                it(@"should generate symbol for 'setIs' iVar", ^{
                    [visitor willBeginVisiting];
    
                    [visitor visitProperty:aProperty];
    
                    [visitor didEndVisiting];
    
                    NSInteger location = [visitor.resultString rangeOfString:[NSString stringWithFormat:@"#define _is%@ _is", [propertyName capitalizeFirstCharacter]]].location;
                    [[theValue(location) shouldNot] equal:theValue(NSNotFound)];
                });
            });

            context(@"when obfuscating 'is' property", ^{
                CDOCProperty *isProperty = [[CDOCProperty alloc] initWithName:[@"is" stringByAppendingString:[propertyName capitalizeFirstCharacter]] attributes:@""];

                it(@"should generate symbol for default getter", ^{
                    [visitor willBeginVisiting];

                    [visitor visitProperty:isProperty];
    
                    [visitor didEndVisiting];
    
                    NSInteger location = [visitor.resultString rangeOfString:[NSString stringWithFormat:@"#define %@", propertyName]].location;
                    [[theValue(location) shouldNot] equal:theValue(NSNotFound)];
                });
    
                it(@"should generate symbol for default setter", ^{
                    [visitor willBeginVisiting];

                    [visitor visitProperty:isProperty];
    
                    [visitor didEndVisiting];
    
                    NSInteger location = [visitor.resultString rangeOfString:[NSString stringWithFormat:@"#define set%@", [propertyName capitalizeFirstCharacter]]].location;
                    [[theValue(location) shouldNot] equal:theValue(NSNotFound)];
                });
    
                it(@"should generate symbol for iVar", ^{
                    [visitor willBeginVisiting];

                    [visitor visitProperty:isProperty];
    
                    [visitor didEndVisiting];
    
                    NSInteger location = [visitor.resultString rangeOfString:[NSString stringWithFormat:@"#define _%@", propertyName]].location;
                    [[theValue(location) shouldNot] equal:theValue(NSNotFound)];
                });
    
                it(@"should generate symbol for 'is' property getter", ^{
                    [visitor willBeginVisiting];

                    [visitor visitProperty:isProperty];
    
                    [visitor didEndVisiting];
    
                    NSInteger location = [visitor.resultString rangeOfString:[NSString stringWithFormat:@"#define is%@", [propertyName capitalizeFirstCharacter]]].location;
                    [[theValue(location) shouldNot] equal:theValue(NSNotFound)];
                });


                it(@"should generate symbol for plain setter for 'is' property", ^{
                    [visitor willBeginVisiting];

                    [visitor visitProperty:isProperty];
    
                    [visitor didEndVisiting];
    
                    NSInteger location = [visitor.resultString rangeOfString:[NSString stringWithFormat:@"#define set%@", [propertyName capitalizeFirstCharacter]]].location;
                    [[theValue(location) shouldNot] equal:theValue(NSNotFound)];
                });
    
                it(@"should generate symbol for 'setIs' setter for 'is' property", ^{
                    [visitor willBeginVisiting];

                    [visitor visitProperty:isProperty];
    
                    [visitor didEndVisiting];
    
                    NSInteger location = [visitor.resultString rangeOfString:[NSString stringWithFormat:@"#define setIs%@", [propertyName capitalizeFirstCharacter]]].location;
                    [[theValue(location) shouldNot] equal:theValue(NSNotFound)];
                });
    
                it(@"should generate symbol for 'setIs' setter for 'is' property", ^{
                    [visitor willBeginVisiting];

                    [visitor visitProperty:isProperty];
    
                    [visitor didEndVisiting];
    
                    NSInteger location = [visitor.resultString rangeOfString:[NSString stringWithFormat:@"#define _is%@ _is", [propertyName capitalizeFirstCharacter]]].location;
                    [[theValue(location) shouldNot] equal:theValue(NSNotFound)];
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

                NSInteger location = [visitor.resultString rangeOfString:[NSString stringWithFormat:@"#define %@", methodName]].location;
                [[theValue(location) shouldNot] equal:theValue(NSNotFound)];
            });

            context(@"when method is a setter", ^{
                beforeEach(^{
                    method = [[CDOCMethod alloc] initWithName:[@"set" stringByAppendingString:[methodName capitalizeFirstCharacter]] typeString:nil];
                });

                it(@"should generate symbol for getter", ^{
                    [visitor willBeginVisiting];

                    [visitor visitInstanceMethod:method propertyState:nil];

                    [visitor didEndVisiting];

                    NSInteger location = [visitor.resultString rangeOfString:[NSString stringWithFormat:@"#define %@", methodName]].location;
                    [[theValue(location) shouldNot] equal:theValue(NSNotFound)];
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

                    NSInteger location = [visitor.resultString rangeOfString:[NSString stringWithFormat:@"#define set%@", [methodName capitalizeFirstCharacter]]].location;
                    [[theValue(location) shouldNot] equal:theValue(NSNotFound)];
                });
            });
        });
    });

SPEC_END
