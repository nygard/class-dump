#import "AllTests.h"

#if 0
#import "CDTypeFormatterUnitTest.h"
#import "CDStructHandlingUnitTest.h"
#import "CDPathUnitTest.h"
#endif

#import "MyFirstTestCase.h"
#import "CDPathUnitTest.h"
#import "CDTypeLexerUnitTest.h"
#import "CDTypeParserUnitTest.h"

@interface NSObject (SenTestRuntimeUtilities)

- (NSArray *) senAllSubclasses;
- (NSArray *) senInstanceInvocations;
- (NSArray *) senAllInstanceInvocations;

@end


@implementation AllTests

+ (void)_foo_updateCache;
{
    NSEnumerator *testCaseEnumerator;
    id testCaseClass = nil;

    testCaseEnumerator = [[SenTestCase senAllSubclasses] objectEnumerator];
    testCaseClass = [testCaseEnumerator nextObject];
    while (testCaseClass != nil) {
        NSString *path;
        SenTestSuite *suite;

        NSLog(@"%s, testCaseClass: %@[%@]", _cmd, testCaseClass, NSStringFromClass(testCaseClass));
        NSLog(@"%s, self: %p, testCaseClass: %p", _cmd, self, testCaseClass);
        if (testCaseClass != self) {
            NSLog(@"default test suite: %@", [testCaseClass defaultTestSuite]);
        }
#if 0
        path = [[testCase bundle] bundlePath];
        suite = [suiteForBundleCache objectForKey:path];

        if (suite == nil) {
            suite = [self emptyTestSuiteNamedFromPath:path];
            [suiteForBundleCache setObject:suite forKey:path];
        }

        [suite addTest:[testCase defaultTestSuite]];
#endif
        testCaseClass = [testCaseEnumerator nextObject];
    }
}



+ (id)defaultTestSuite;
{
    SenTestSuite *allTests, *orderedTests, *unorderedTests;
    NSMutableArray *order;
    unsigned int count, index;

    order = [NSMutableArray array];
    [order addObject:[MyFirstTestCase class]];
    [order addObject:[CDPathUnitTest class]];
    //[order addObject:[CDTypeLexerUnitTest class]];
    //[order addObject:[CDTypeParserUnitTest class]];

    NSLog(@"order: %@", order);

    allTests = [SenTestSuite testSuiteWithName:@"All Tests"];
    orderedTests = [SenTestSuite testSuiteWithName:@"Ordered Tests"];
    unorderedTests = [SenTestSuite testSuiteWithName:@"Unordered Tests"];
    [allTests addTest:orderedTests];
    [allTests addTest:unorderedTests];

    // First, set up the tests we want run in a particular order
    count = [order count];
    for (index = 0; index < count; index++)
        [orderedTests addTest:[SenTestSuite testSuiteForTestCaseClass:[order objectAtIndex:index]]];

    // Then search for any tests that we didn't get from the manual setup above
    {
        NSMutableSet *used = [NSMutableSet set];
        NSArray *allTestCaseSubclasses;

        [used addObjectsFromArray:order];
        [used addObject:self];
        [used addObject:[SenInterfaceTestCase class]]; // Dunno why it's picking this up, skip it.

        allTestCaseSubclasses = [SenTestCase senAllSubclasses];
        count = [allTestCaseSubclasses count];
        for (index = 0; index < count; index++) {
            id aClass;

            aClass = [allTestCaseSubclasses objectAtIndex:index];
            if ([used containsObject:aClass] == NO) {
                NSLog(@"Adding unordered test: %@", aClass);
                //[unorderedTests addTest:[SenTestSuite testSuiteForTestCaseClass:aClass]];
                [unorderedTests addTest:[aClass defaultTestSuite]];
                [used addObject:aClass];
            }
        }
    }

    return allTests;
}

#if 0
+ (TestSuite *)suite;
{
    TestSuite *suite;

    suite = [TestSuite suiteWithName:@"My Tests"];

    // Add your tests here...
    [suite addTest:[TestSuite suiteWithClass:[CDTypeLexerUnitTest class]]];
    [suite addTest:[TestSuite suiteWithClass:[CDTypeParserUnitTest class]]];
    [suite addTest:[TestSuite suiteWithClass:[CDTypeFormatterUnitTest class]]];
    [suite addTest:[TestSuite suiteWithClass:[CDStructHandlingUnitTest class]]];
    [suite addTest:[TestSuite suiteWithClass:[CDPathUnitTest class]]];
    return suite;
}
#endif

@end
