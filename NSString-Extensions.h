#import <Foundation/NSString.h>

@interface NSString (CDExtensions)

- (id)initWithCString:(const char *)bytes maximumLength:(unsigned int)maximumLength;
//+ (NSString *)spacesOfLength:(int)length;
+ (NSString *)spacesIndentedToLevel:(int)level;
+ (NSString *)spacesIndentedToLevel:(int)level spacesPerLevel:(int)spacesPerLevel;
+ (NSString *)stringWithUnichar:(unichar)character;

@end
