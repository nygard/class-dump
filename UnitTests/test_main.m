// The test_main.m file

#import <ObjcUnit/ObjcUnit.h>
#import "AllTests.h"

int main(int argc, const char *argv[])
{
    return TestRunnerMain([AllTests class]);
}

