#import "CDTypeFormatter.h"

#include <assert.h>

#include "datatypes.h"
#import "CDTypeParser.h"

#import <Foundation/Foundation.h>
#import "NSString-Extensions.h"

//----------------------------------------------------------------------

@implementation CDTypeFormatter

+ (NSString *)formatVariable:(NSString *)name type:(NSString *)type atLevel:(int)level;
{
    CDTypeParser *aParser;
    struct my_objc_type *result;
    NSMutableString *resultString;

    aParser = [[CDTypeParser alloc] init];
    result = [aParser parseType:type];

    if (result == NULL) {
        [aParser release];
        return nil;
    }

    resultString = [NSMutableString string];
    result->var_name = [name retain];
    [resultString appendString:[NSString spacesIndentedToLevel:level]];
    [resultString appendString:string_from_type(result, nil, NO, level)];

    free_allocated_methods();
    free_allocated_types();
    [aParser release];

    return resultString;
}

+ (NSString *)formatMethodName:(NSString *)name type:(NSString *)type;
{
    CDTypeParser *aParser;
    struct method_type *result;
    NSMutableString *resultString;
    NSString *str;

    aParser = [[CDTypeParser alloc] init];
    result = [aParser parseMethodType:type];

    if (result == NULL) {
        [aParser release];
        return nil;
    }

    resultString = [NSMutableString string];
    str = string_from_method_type(name, result);
    if (str != nil)
        [resultString appendString:str];
    [resultString appendString:@";"];

    free_allocated_methods();
    free_allocated_types();
    [aParser release];

    return resultString;
}

@end

