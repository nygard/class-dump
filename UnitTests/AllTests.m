#import "AllTests.h"

#import "CDTypeParserUnitTest.h"

@implementation AllTests

+ (TestSuite *)suite;
{
    TestSuite *suite;

    suite = [TestSuite suiteWithName:@"My Tests"];

    // Add your tests here...
    [suite addTest:[TestSuite suiteWithClass:[CDTypeParserUnitTest class]]];

    return suite;
}

@end
