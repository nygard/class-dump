#import "AllTests.h"

#import "CDTypeFormatterUnitTest.h"
#import "CDTypeParserUnitTest.h"
#import "CDStructHandlingUnitTest.h"
#import "CDPathUnitTest.h"

@implementation AllTests

+ (TestSuite *)suite;
{
    TestSuite *suite;

    suite = [TestSuite suiteWithName:@"My Tests"];

    // Add your tests here...
    [suite addTest:[TestSuite suiteWithClass:[CDTypeParserUnitTest class]]];
    [suite addTest:[TestSuite suiteWithClass:[CDTypeFormatterUnitTest class]]];
    [suite addTest:[TestSuite suiteWithClass:[CDStructHandlingUnitTest class]]];
    [suite addTest:[TestSuite suiteWithClass:[CDPathUnitTest class]]];

    return suite;
}

@end
