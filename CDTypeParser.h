#import <Foundation/NSObject.h>
#include "datatypes.h"

@interface CDTypeParser : NSObject
{
    //int ident_state;
    int lookahead;
}

//- (id)init;
//- (void)dealloc;

- (void)match:(int)token;
- (void)match:(int)token allowIdentifier:(BOOL)shouldAllowIdentifier;
- (void)error:(NSString *)errorString;

- (struct my_objc_type *)parseType:(const char *)type name:(const char *)name;
- (struct method_type *)parseMethodName:(const char *)name type:(const char *)type;

- (struct my_objc_type *)parseType;

- (struct my_objc_type *)parseUnionTypes;
- (struct my_objc_type *)parseOptionalFormat;
- (struct my_objc_type *)parseTagList;
- (struct my_objc_type *)parseTag;

- (char *)parseTypeName;
- (char *)parseIdentifier;
- (char *)parseNumber;
- (char *)parseQuotedName;

- (BOOL)isLookaheadInModifierSet;
- (BOOL)isLookaheadInSimpleTypeSet;
- (BOOL)isLookaheadInTypeSet;

@end
