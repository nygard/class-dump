#import "AllTests.h"

#import "CDTypeFormatterUnitTest.h"

@implementation AllTests

+ (TestSuite *)suite;
{
    TestSuite *suite;

    suite = [TestSuite suiteWithName:@"My Tests"];

    // Add your tests here...
    [suite addTest:[TestSuite suiteWithClass:[CDTypeFormatterUnitTest class]]];

    return suite;
}

@end
