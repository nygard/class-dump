#import <Foundation/NSObject.h>

@class NSString;

@interface CDTypeFormatter : NSObject
{
}

+ (NSString *)formatVariable:(NSString *)name type:(NSString *)type atLevel:(int)level;
+ (NSString *)formatMethodName:(NSString *)methodName type:(NSString *)type;

@end
