#import <Foundation/NSObject.h>
#include "datatypes.h"

@class CDTypeLexer;

extern NSString *CDSyntaxError;

@interface CDTypeParser : NSObject
{
    CDTypeLexer *lexer;
    int lookahead;
}

- (id)initWithType:(NSString *)aType;
- (void)dealloc;

// TODO (2003-12-18): Or add subclass, CDMethodTypeParser, and then just have them -parse?  Nah, different return types.
- (struct method_type *)parseMethodType;
- (struct my_objc_type *)parseType;

@end

@interface CDTypeParser (Private)

- (void)match:(int)token;
- (void)match:(int)token allowIdentifier:(BOOL)shouldAllowIdentifier;
- (void)error:(NSString *)errorString;

- (struct method_type *)_parseMethodType;
- (struct my_objc_type *)_parseType;

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
