#import <Foundation/NSObject.h>
#import <Foundation/NSString.h> // for unichar

#define TK_EOS 0
#define TK_NUMBER 257
#define TK_IDENTIFIER 258
#define T_NAMED_OBJECT 259

@class NSCharacterSet, NSScanner;

@interface CDTypeLexer : NSObject
{
    NSScanner *scanner;
    BOOL isInIdentifierState;
    NSString *lexText;

    BOOL shouldShowLexing;
}

+ (NSCharacterSet *)otherCharacterSet;
+ (NSCharacterSet *)identifierStartCharacterSet;
+ (NSCharacterSet *)identifierCharacterSet;

- (id)initWithString:(NSString *)aString;
- (void)dealloc;

- (BOOL)isInIdentifierState;
- (void)setIsInIdentifierState:(BOOL)newFlag;

- (BOOL)shouldShowLexing;
- (void)setShouldShowLexing:(BOOL)newFlag;

- (NSString *)string;
- (int)nextToken;

- (NSString *)lexText;
- (void)_setLexText:(NSString *)newString;

- (unichar)peekChar;

@end
