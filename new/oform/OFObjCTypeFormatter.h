#import <OmniFoundation/OFObject.h>

@interface OFObjCTypeFormatter : OFObject
{
}

+ (NSString *)formattedType:(NSString *)type forIvar:(NSString *)name;

+ (BOOL)verifyType:(NSString *)type forIvar:(NSString *)name expectedResult:(NSString *)expectedResult;

+ (void)test;

@end
