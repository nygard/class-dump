#import "AllTests.h"

#import "CDTypeFormatterUnitTest.h"
#import "CDStructHandlingUnitTest.h"

@implementation AllTests

+ (TestSuite *)suite;
{
    TestSuite *suite;

    suite = [TestSuite suiteWithName:@"My Tests"];

    // Add your tests here...
    [suite addTest:[TestSuite suiteWithClass:[CDTypeFormatterUnitTest class]]];
    [suite addTest:[TestSuite suiteWithClass:[CDStructHandlingUnitTest class]]];

    return suite;
}

@end
