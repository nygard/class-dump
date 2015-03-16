#import <Kiwi/Kiwi.h>

#import "CDdSYMProcessor.h"

SPEC_BEGIN(CDdSYMProcessorSpec)

describe(@"CDdSYMProcessor", ^{
    __block CDdSYMProcessor *processor;
    __block NSData *dwarfData;
    __block NSDictionary *mapping;
    __block NSUInteger dwarfDataLength;
    __block char *bytes = "tralsjdioashfduhdsioafgsdaoifgasigf18\0\0\0\0\0    ysetJ0s\0\0\0\0\0\t\t\tsdfewq43t4f\t\tesdfsefe\nisF2m\0\0\0\0\0\0fdsoifh32[ef1";
    __block char *expectedResult = "tralsjdioashfduhdsioafgsdaoifgasigf18\0\0\0\0\0    ysetSections\t\t\tsdfewq43t4f\t\tesdfsefe\nisCellClassfdsoifh32[ef1";;

    beforeEach(^{
        processor = [[CDdSYMProcessor alloc] init];
        dwarfDataLength = 130 * sizeof(char);
        dwarfData = [NSData dataWithBytes:bytes length:dwarfDataLength];
        mapping = @{
                @"setJ0s" : @"setSections",
                @"isF2m" : @"isCellClass",
        };
    });

    describe(@"processing dwarf-like data", ^{
        it(@"input file should not change", ^{
            NSData *originalDwarf = dwarfData;
            [processor processDwarfdump:dwarfData withSymbols:mapping];
            [[dwarfData should] equal:originalDwarf];
        });
        it(@"input and output data should have the same size", ^{
            NSData *result = [processor processDwarfdump:dwarfData withSymbols:mapping];
            [[theValue(result.length) should] equal:theValue(dwarfData.length)];
        });
        it(@"should return pseudo string equal to expectedResults", ^{
            NSData *result = [processor processDwarfdump:dwarfData withSymbols:mapping];
            char *resultPseudoString = (char *)result.bytes;
            NSUInteger differences = 0;
            for (int i=0; i<result.length/sizeof(char); ++i) {
                if (resultPseudoString[i] != expectedResult[i]) {
                    differences++;
                }
            }
            [[theValue(differences) should] equal:theValue(0)];
        });
    });
});

SPEC_END
