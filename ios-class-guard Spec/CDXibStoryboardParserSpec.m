#import <Kiwi/Kiwi.h>

#import "CDXibStoryboardParser.h"

SPEC_BEGIN(CDXibStoryboardParserSpec)

    describe(@"CDXibStoryboardParser", ^{
        __block CDXibStoryboardParser *parser;

        beforeEach(^{
            parser = [[CDXibStoryboardParser alloc] init];
        });

        describe(@"parsing Xib", ^{
            __block NSURL *fileUrl;
            NSString *obfuscatedClass = @"abc";
            NSString *className = @"CustomCellTableViewCell";

            NSString *obfuscatedOutlet = @"cde";
            NSString *outletName = @"aLabel";

            NSString *obfuscatedAction = @"cdeAction";
            NSString *action = @"buttonTapped";

            NSString *obfuscatedOutletCollection = @"cdeCollection";
            NSString *outletCollection = @"outletCollection";

            NSDictionary *symbols = @{className : obfuscatedClass,
                    outletName : obfuscatedOutlet,
                    action : obfuscatedAction,
                    outletCollection : obfuscatedOutletCollection
            };

            beforeEach(^{
                for (NSBundle *bundle in [NSBundle allBundles]) {
                    NSURL *url = [bundle URLForResource:@"CustomCellTableViewCell_xib" withExtension:@"txt"];
                    if (url) {
                        fileUrl = url;
                    }
                }
            });
            it(@"should generate symbol for custom class", ^{
                NSData *obfuscatedData = [parser obfuscatedXmlData:[NSData dataWithContentsOfURL:fileUrl] symbols:symbols];
                NSString *resultString = [[NSString alloc] initWithData:obfuscatedData encoding:NSUTF8StringEncoding];
                
                NSRange range = [resultString rangeOfString:obfuscatedClass];

                [[theValue(range.location) shouldNot] equal:theValue(NSNotFound)];
            });

            it(@"should generate symbol for outlet", ^{
                NSData *obfuscatedData = [parser obfuscatedXmlData:[NSData dataWithContentsOfURL:fileUrl] symbols:symbols];
                NSString *resultString = [[NSString alloc] initWithData:obfuscatedData encoding:NSUTF8StringEncoding];

                NSRange range = [resultString rangeOfString:obfuscatedOutlet];

                [[theValue(range.location) shouldNot] equal:theValue(NSNotFound)];
            });

            it(@"should generate symbol for action", ^{
                NSData *obfuscatedData = [parser obfuscatedXmlData:[NSData dataWithContentsOfURL:fileUrl] symbols:symbols];
                NSString *resultString = [[NSString alloc] initWithData:obfuscatedData encoding:NSUTF8StringEncoding];

                NSRange range = [resultString rangeOfString:obfuscatedAction];

                [[theValue(range.location) shouldNot] equal:theValue(NSNotFound)];
            });

            it(@"should generate symbol for outlet collection", ^{
                NSData *obfuscatedData = [parser obfuscatedXmlData:[NSData dataWithContentsOfURL:fileUrl] symbols:symbols];
                NSString *resultString = [[NSString alloc] initWithData:obfuscatedData encoding:NSUTF8StringEncoding];

                NSRange range = [resultString rangeOfString:obfuscatedOutletCollection];

                [[theValue(range.location) shouldNot] equal:theValue(NSNotFound)];
            });
        });

        describe(@"parsing Storyboard", ^{
            __block NSURL *fileUrl;

            NSString *className = @"XTTableViewController";
            NSString *obfuscatedClass = @"abc";

            NSString *obfuscatedOutlet = @"cde";
            NSString *outletName = @"dataSource";

            NSString *obfuscatedAction = @"cdeAction";
            NSString *action = @"buttonTapped";

            NSString *obfuscatedOutletCollection = @"cdeCollection";
            NSString *outletCollection = @"outletCollection";

            NSDictionary *symbols = @{className : obfuscatedClass,
                    outletName : obfuscatedOutlet,
                    action : obfuscatedAction,
                    outletCollection : obfuscatedOutletCollection
            };

            beforeEach(^{
                for (NSBundle *bundle in [NSBundle allBundles]) {
                    NSURL *url = [bundle URLForResource:@"Main_iPhone_storyboard" withExtension:@"txt"];
                    if (url) {
                        fileUrl = url;
                    }
                }
            });
            it(@"should generate symbol for custom class", ^{
                NSData *obfuscatedData = [parser obfuscatedXmlData:[NSData dataWithContentsOfURL:fileUrl] symbols:symbols];
                NSString *resultString = [[NSString alloc] initWithData:obfuscatedData encoding:NSUTF8StringEncoding];

                NSRange range = [resultString rangeOfString:obfuscatedClass];

                [[theValue(range.location) shouldNot] equal:theValue(NSNotFound)];
            });

            it(@"should generate symbol for outlet", ^{
                NSData *obfuscatedData = [parser obfuscatedXmlData:[NSData dataWithContentsOfURL:fileUrl] symbols:symbols];
                NSString *resultString = [[NSString alloc] initWithData:obfuscatedData encoding:NSUTF8StringEncoding];

                NSRange range = [resultString rangeOfString:obfuscatedOutlet];

                [[theValue(range.location) shouldNot] equal:theValue(NSNotFound)];
            });

            it(@"should generate symbol for outlet", ^{
                NSData *obfuscatedData = [parser obfuscatedXmlData:[NSData dataWithContentsOfURL:fileUrl] symbols:symbols];
                NSString *resultString = [[NSString alloc] initWithData:obfuscatedData encoding:NSUTF8StringEncoding];

                NSRange range = [resultString rangeOfString:obfuscatedOutlet];

                [[theValue(range.location) shouldNot] equal:theValue(NSNotFound)];
            });

            it(@"should generate symbol for action", ^{
                NSData *obfuscatedData = [parser obfuscatedXmlData:[NSData dataWithContentsOfURL:fileUrl] symbols:symbols];
                NSString *resultString = [[NSString alloc] initWithData:obfuscatedData encoding:NSUTF8StringEncoding];

                NSRange range = [resultString rangeOfString:obfuscatedAction];

                [[theValue(range.location) shouldNot] equal:theValue(NSNotFound)];
            });

            it(@"should generate symbol for outlet collection", ^{
                NSData *obfuscatedData = [parser obfuscatedXmlData:[NSData dataWithContentsOfURL:fileUrl] symbols:symbols];
                NSString *resultString = [[NSString alloc] initWithData:obfuscatedData encoding:NSUTF8StringEncoding];

                NSRange range = [resultString rangeOfString:obfuscatedOutletCollection];

                [[theValue(range.location) shouldNot] equal:theValue(NSNotFound)];
            });
        });
    });

SPEC_END
