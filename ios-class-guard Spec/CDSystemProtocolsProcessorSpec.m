#import <Kiwi/Kiwi.h>
#import "CDSystemProtocolsProcessor.h"

SPEC_BEGIN(CDSystemProtocolsProcessorSpec)
    describe(@"CDSystemProtocolsProcessor", ^{
        __block CDSystemProtocolsProcessor* parser;

        beforeEach(^{
            NSArray* sdkRoots = @[@"/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/",
                                  @"/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/"];

            for (NSString *sdkRoot in sdkRoots) {
                NSArray* sdkPaths = [[NSFileManager defaultManager]
                             contentsOfDirectoryAtPath:sdkRoot
                             error:NULL];
            
                for (NSString *sdkPath in sdkPaths) {
                    if ([sdkPath hasPrefix:@"iPhoneOS"]) {
                        parser = [[CDSystemProtocolsProcessor alloc] initWithSdkPath:[sdkRoot stringByAppendingString:sdkPath]];
                        return;
                    }
                }
            }
        });

        describe(@"retrieving protocol symbols to exclude", ^{
            __block NSArray *symbols;
            beforeAll(^{
                symbols = [parser systemProtocolsSymbolsToExclude];
            });

            it(@"should contain UIWebViewDelegate, UIPickerViewDelegate, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate", ^{
                [[symbols should] contain:@"UIWebViewDelegate"];
                [[symbols should] contain:@"UIPickerViewDelegate"];
                [[symbols should] contain:@"UITableViewDelegate"];
                [[symbols should] contain:@"UITableViewDataSource"];
                [[symbols should] contain:@"UINavigationControllerDelegate"];
            });
        });
    });
SPEC_END
