#import <Foundation/NSObject.h>

@class NSString;

@interface CDTypeFormatter : NSObject
{
    BOOL shouldExpandStructures;
}

+ (id)sharedTypeFormatter;

- (BOOL)shouldExpandStructures;
- (void)setShouldExpandStructures:(BOOL)newFlag;

- (NSString *)formatVariable:(NSString *)name type:(NSString *)type atLevel:(int)level;
- (NSString *)formatVariable:(NSString *)name type:(NSString *)type atLevel:(int)level expand:(BOOL)shouldExpand;
- (NSString *)formatMethodName:(NSString *)methodName type:(NSString *)type;

@end
