#import <Foundation/NSObject.h>
#include "datatypes.h"

@class CDTypeLexer;

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

- (void)match:(int)token;
- (void)match:(int)token allowIdentifier:(BOOL)shouldAllowIdentifier;
- (void)error:(NSString *)errorString;

- (NSString *)parseType:(NSString *)type name:(NSString *)name;
- (struct method_type *)parseMethodName:(NSString *)name type:(NSString *)type;

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

@end
