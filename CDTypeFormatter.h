#import <Foundation/NSObject.h>

@class NSString;

@interface CDTypeFormatter : NSObject
{
    BOOL shouldExpand;
    BOOL shouldAutoExpand;

    // Not ideal
    id nonretainedDelegate;
}

+ (id)sharedTypeFormatter;
+ (id)sharedIvarTypeFormatter;
+ (id)sharedMethodTypeFormatter;
+ (id)sharedStructDeclarationTypeFormatter;

- (BOOL)shouldExpand;
- (void)setShouldExpand:(BOOL)newFlag;

- (BOOL)shouldAutoExpand;
- (void)setShouldAutoExpand:(BOOL)newFlag;

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

- (NSString *)formatVariable:(NSString *)name type:(NSString *)type atLevel:(int)level;
- (NSString *)formatMethodName:(NSString *)methodName type:(NSString *)type;

- (NSString *)typedefNameForStruct:(NSString *)structTypeString;

@end
