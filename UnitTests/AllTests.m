#import "AllTests.h"

#import "CDPathUnitTest.h"
#import "CDTypeLexerUnitTest.h"
#import "CDTypeParserUnitTest.h"
#import "CDTypeFormatterUnitTest.h"
#import "CDStructHandlingUnitTest.h"

@interface NSObject (SenTestRuntimeUtilities)

- (NSArray *) senAllSubclasses;
- (NSArray *) senInstanceInvocations;
- (NSArray *) senAllInstanceInvocations;

@end


@implementation AllTests

// This is here to help me understand what the original method does.  Formatting/naming is key to understanding.
+ (void)_foo_updateCache;
{
    NSEnumerator *testCaseEnumerator;
    id testCaseClass = nil;

    testCaseEnumerator = [[SenTestCase senAllSubclasses] objectEnumerator];
    testCaseClass = [testCaseEnumerator nextObject];
    while (testCaseClass != nil) {
        NSString *path;
        SenTestSuite *suite;

        NSLog(@"%s, testCaseClass: %@[%@]", __cmd, testCaseClass, NSStringFromClass(testCaseClass));
        NSLog(@"%s, self: %p, testCaseClass: %p", __cmd, self, testCaseClass);
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
    [order addObject:[CDPathUnitTest class]];
    [order addObject:[CDTypeLexerUnitTest class]];
    [order addObject:[CDTypeParserUnitTest class]];
    //[order addObject:[CDTypeFormatterUnitTest class]];
    [order addObject:[CDStructHandlingUnitTest class]];
    [order addObject:[CDTypeFormatterUnitTest class]];

    NSLog(@"order: %@", order);

    allTests = [SenTestSuite testSuiteWithName:@"All Tests"];
    orderedTests = [SenTestSuite testSuiteWithName:@"Order"];
    unorderedTests = [SenTestSuite testSuiteWithName:@"Chaos"];
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
                //[unorderedTests addTest:[SenTestSuite testSuiteForTestCaseClass:aClass]];
                [unorderedTests addTest:[aClass defaultTestSuite]];
                [used addObject:aClass];
            }
        }
    }

    return allTests;
}

@end
