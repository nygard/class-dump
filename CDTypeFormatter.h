#import <Foundation/NSObject.h>

@class NSString;

@interface CDTypeFormatter : NSObject
{
    BOOL shouldExpand; // But just top level struct, level == 0
    BOOL shouldAutoExpand;
    int baseLevel;

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

- (int)baseLevel;
- (void)setBaseLevel:(int)newBaseLevel;

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

- (NSString *)_specialCaseVariable:(NSString *)name type:(NSString *)type;
- (NSString *)formatVariable:(NSString *)name type:(NSString *)type;
- (NSString *)formatMethodName:(NSString *)methodName type:(NSString *)type;

- (NSString *)typedefNameForStruct:(NSString *)structTypeString;

@end
