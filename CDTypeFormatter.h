#import <Foundation/NSObject.h>

@class NSString;

@interface CDTypeFormatter : NSObject
{
}

+ (NSString *)formatVariable:(NSString *)name type:(NSString *)type atLevel:(int)level;
+ (NSString *)formatMethodName:(NSString *)name type:(NSString *)type;

@end
