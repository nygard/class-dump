#import <Foundation/NSObject.h>
#include "datatypes.h"

@class CDTypeLexer;

extern NSString *CDSyntaxError;

@interface CDTypeParser : NSObject
{
    CDTypeLexer *lexer;
    int lookahead;
    BOOL shouldShowLexing;
}

- (id)init;
- (void)dealloc;

- (BOOL)shouldShowLexing;
- (void)setShouldShowLexing:(BOOL)newFlag;

- (NSString *)formatVariable:(NSString *)name type:(NSString *)type atLevel:(int)level;
- (NSString *)formatMethodName:(NSString *)name type:(NSString *)type;

@end

@interface CDTypeParser (Private)

- (void)match:(int)token;
- (void)match:(int)token allowIdentifier:(BOOL)shouldAllowIdentifier;
- (void)error:(NSString *)errorString;

- (struct method_type *)parseMethodType;

- (struct my_objc_type *)parseType;
- (struct my_objc_type *)parseUnionTypes;
- (struct my_objc_type *)parseOptionalFormat;
- (struct my_objc_type *)parseTagList;
- (struct my_objc_type *)parseTag;

- (NSString *)parseTypeName;
- (NSString *)parseIdentifier;
- (NSString *)parseNumber;
- (NSString *)parseQuotedName;

- (BOOL)isLookaheadInModifierSet;
- (BOOL)isLookaheadInSimpleTypeSet;
- (BOOL)isLookaheadInTypeSet;
- (BOOL)isLookaheadInTypeStartSet;

@end
