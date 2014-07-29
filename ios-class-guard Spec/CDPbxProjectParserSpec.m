#import <Kiwi/Kiwi.h>

#import "CDPbxProjectParser.h"
#import "CDPbxProjectTarget.h"

SPEC_BEGIN(CDPbxProjectParserSpec)

    describe(@"CDPbxProjectParser", ^{
        __block CDPbxProjectParser *parser;
        __block NSDictionary *projectJSON;

        beforeEach(^{
            NSURL *fileUrl = nil;
            for (NSBundle *bundle in [NSBundle allBundles]) {
                NSURL *url = [bundle URLForResource:@"podsProject" withExtension:@"json"];
                if (url) {
                    fileUrl = url;
                }
            }

            NSData *projectData = [NSData dataWithContentsOfURL:fileUrl];
            projectJSON = [NSJSONSerialization JSONObjectWithData:projectData options:0 error:nil];
            parser = [[CDPbxProjectParser alloc] initWithJsonDictionary:projectJSON];
        });

        describe(@"parsing project", ^{
            it(@"should find all targets", ^{
                NSSet *targets = [parser findTargets];
                NSArray *targetNames = @[@"Pods-PodsTest", @"Pods-PodsTest-CocoaLumberjack", @"Pods-PodsTest-AFNetworking",
                        @"Pods-PodsTest-PLImageManager", @"Pods-PodsTest-PLCoreDataUtils"];
                [[theValue(targets.count) should] equal:theValue(targetNames.count)];
                NSSet *filteredTargets = [targets objectsPassingTest:^BOOL(id obj, BOOL *stop) {
                    CDPbxProjectTarget *target = obj;
                    return [targetNames containsObject:target.targetName];
                }];
                [[theValue(filteredTargets.count) should] equal:theValue(targetNames.count)];
            });

            it(@"should find all precompiled header names", ^{
                NSSet *targets = [parser findTargets];
                NSArray *headerNames = @[@"Pods-PodsTest-CocoaLumberjack-prefix.pch", @"Pods-PodsTest-AFNetworking-prefix.pch",
                        @"Pods-PodsTest-PLImageManager-prefix.pch", @"Pods-PodsTest-PLCoreDataUtils-prefix.pch"];
                NSSet *filteredTargets = [targets objectsPassingTest:^BOOL(id obj, BOOL *stop) {
                    CDPbxProjectTarget *target = obj;
                    return [headerNames containsObject:target.headerName];
                }];
                [[theValue(filteredTargets.count) should] equal:theValue(headerNames.count)];

            });

            it(@"should find all traget configuration file names", ^{
                NSSet *targets = [parser findTargets];
                NSArray *configurations = @[@"Pods-PodsTest.xcconfig", @"Pods-PodsTest-AFNetworking-Private.xcconfig",
                        @"Pods-PodsTest-CocoaLumberjack-Private.xcconfig", @"Pods-PodsTest-PLCoreDataUtils-Private.xcconfig",
                        @"Pods-PodsTest-PLImageManager-Private.xcconfig"];
                NSSet *filteredTargets = [targets objectsPassingTest:^BOOL(id obj, BOOL *stop) {
                    CDPbxProjectTarget *target = obj;
                    return [configurations containsObject:target.configFile];
                }];
                [[theValue(filteredTargets.count) should] equal:theValue(configurations.count)];
            });
        });
    });

SPEC_END
