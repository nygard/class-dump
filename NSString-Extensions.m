#import "NSString-Extensions.h"

#import <Foundation/Foundation.h>

@implementation NSString (CDExtensions)

- (id)initWithCString:(const char *)bytes maximumLength:(unsigned int)maximumLength;
{
    char *buf;

    buf = alloca(maximumLength + 1);
    if (buf == NULL) {
        [self release];
        return nil;
    }

    strncpy(buf, bytes, maximumLength);
    buf[maximumLength] = 0;

    return [self initWithCString:buf];
}

+ (NSString *)spacesIndentedToLevel:(int)level;
{
    return [self spacesIndentedToLevel:level spacesPerLevel:4];
}

+ (NSString *)spacesIndentedToLevel:(int)level spacesPerLevel:(int)spacesPerLevel;
{
    NSString *spaces = @"                                        ";
    NSString *levelSpaces;
    NSMutableString *str;
    int l;

    assert(spacesPerLevel <= [spaces length]);
    levelSpaces = [spaces substringToIndex:spacesPerLevel];

    str = [NSMutableString string];
    for (l = 0; l < level; l++)
        [str appendString:levelSpaces];

    return str;
}

+ (NSString *)stringWithUnichar:(unichar)character;
{
    return [NSString stringWithCharacters:&character length:1];
}

@end
